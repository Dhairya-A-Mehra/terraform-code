import json
import uuid
import time
import os
import boto3

dynamodb = boto3.resource("dynamodb")

review_tokens_table = dynamodb.Table(os.environ["REVIEW_TOKENS_TABLE"])
feedback_table = dynamodb.Table(os.environ["FEEDBACK_TABLE"])


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

        review_tokens_table.put_item(
            Item={
                "token_id": token_id,
                "order_id": body["order_id"],
                "customer_email": body["customer_email"],
                "product_id": body["product_id"],
                "expires_at": expiry,
                "used": False,
                "created_at": now
            }
        )

        review_link = f"https://yourfrontend.com/review?token={token_id}"

        return {
            "statusCode": 200,
            "body": json.dumps({"review_link": review_link})
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
                "product_id": item["product_id"],
                "customer_email": item["customer_email"]
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
                "id": str(uuid.uuid4()),
                "product_id": item["product_id"],
                "feedback": body["feedback"],
                "rating": body.get("rating", 0),
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

