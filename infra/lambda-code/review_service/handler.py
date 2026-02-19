import json
import uuid
import time
import os
import boto3

dynamodb = boto3.resource("dynamodb")
ses = boto3.client("ses", region_name="ca-central-1")

review_tokens_table = dynamodb.Table(os.environ["REVIEW_TOKENS_TABLE"])
feedback_table = dynamodb.Table(os.environ["FEEDBACK_TABLE"])
FRONTEND_URL = os.environ.get("FRONTEND_URL", "https://yourfrontend.com")
SENDER_EMAIL = os.environ.get("SENDER_EMAIL", "noreply@yourdomain.com")

def lambda_handler(event, context):
    path = event.get("rawPath")
    method = event.get("requestContext", {}).get("http", {}).get("method")

    # -------------------------------
    # 1️⃣ Simulate Purchase
    # -------------------------------
    if path == "/simulate-purchase" and method == "POST":
        body = json.loads(event["body"])
        token_id = str(uuid.uuid4())
        now = int(time.time())
        expiry = now + (72 * 3600)

        customer_email = body["customer_email"]
        customer_name  = body.get("customer_name", "Customer")
        product_id     = body["product_id"]
        product_name   = body.get("product_name", product_id)
        brand_id       = body.get("brand_id", "unknown")

        review_tokens_table.put_item(
            Item={
                "token_id":       token_id,
                "order_id":       body["order_id"],
                "customer_email": customer_email,
                "customer_name":  customer_name,
                "product_id":     product_id,
                "product_name":   product_name,
                "brand_id":       brand_id,
                "expires_at":     expiry,
                "used":           False,
                "created_at":     now
            }
        )

        review_link = f"{FRONTEND_URL}/review?token={token_id}"

        # Send review request email via SES
        try:
            ses.send_email(
                Source=SENDER_EMAIL,
                Destination={"ToAddresses": [customer_email]},
                Message={
                    "Subject": {
                        "Data": f"Share your feedback for {product_name}"
                    },
                    "Body": {
                        "Html": {
                            "Data": f"""
                            <div style="font-family:sans-serif;max-width:600px;margin:0 auto;">
                                <h2>Hi {customer_name},</h2>
                                <p>Thank you for purchasing <strong>{product_name}</strong>.</p>
                                <p>We would love to hear your feedback. Please click the button below to leave a review.</p>
                                <a href="{review_link}"
                                   style="display:inline-block;background:#4F46E5;color:white;
                                          padding:12px 24px;border-radius:6px;text-decoration:none;
                                          font-weight:bold;margin:16px 0;">
                                  Leave a Review
                                </a>
                                <p style="color:#888;font-size:13px;">This link expires in 72 hours.</p>
                                <p style="color:#888;font-size:13px;">If you did not make this purchase, please ignore this email.</p>
                            </div>
                            """
                        }
                    }
                }
            )
        except Exception as e:
            # Log error but don't fail the request — token is already created
            print(f"SES email failed: {str(e)}")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "review_link": review_link
            })
        }

    # -------------------------------
    # 2️⃣ Validate Token
    # -------------------------------
    if path == "/review" and method == "GET":
        token = event.get("queryStringParameters", {}).get("token")
        response = review_tokens_table.get_item(Key={"token_id": token})

        if "Item" not in response:
            return {"statusCode": 400, "body": "Invalid token"}

        item = response["Item"]

        if item["used"]:
            return {"statusCode": 400, "body": "Already submitted"}

        if item["expires_at"] < int(time.time()):
            return {"statusCode": 400, "body": "Token expired"}

        return {
            "statusCode": 200,
            "body": json.dumps({
                "product_id":     item["product_id"],
                "product_name":   item.get("product_name", item["product_id"]),
                "customer_email": item["customer_email"],
                "customer_name":  item.get("customer_name", "Customer")
            })
        }

    # -------------------------------
    # 3️⃣ Submit Review
    # -------------------------------
    if path == "/submit-review" and method == "POST":
        body = json.loads(event["body"])
        token = body["token"]
        response = review_tokens_table.get_item(Key={"token_id": token})

        if "Item" not in response:
            return {"statusCode": 400, "body": "Invalid token"}

        item = response["Item"]

        if item["used"] or item["expires_at"] < int(time.time()):
            return {"statusCode": 400, "body": "Token invalid"}

        feedback_table.put_item(
            Item={
                "id":         str(uuid.uuid4()),
                "product_id": item["product_id"],
                "brand_id":   item.get("brand_id", "unknown"),
                "feedback":   body["feedback"],
                "rating":     body.get("rating", 0),
                "created_at": int(time.time())
            }
        )

        review_tokens_table.update_item(
            Key={"token_id": token},
            UpdateExpression="SET used = :u",
            ExpressionAttributeValues={":u": True}
        )

        return {"statusCode": 200, "body": "Review submitted"}

    return {"statusCode": 404, "body": "Route not found"}
