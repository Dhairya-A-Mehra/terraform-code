import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
bedrock = boto3.client('bedrock-runtime')

table = dynamodb.Table(os.environ['TABLE_NAME'])

MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"

def lambda_handler(event, context):

    if "Records" not in event:
        print("No Records key found. Likely manual invocation.")
        return {"statusCode": 200}

    for record in event["Records"]:

        try:
            # Process only INSERT events
            if record.get("eventName") != "INSERT":
                continue

            new_image = record.get("dynamodb", {}).get("NewImage", {})

            if "feedback" not in new_image or "id" not in new_image:
                print("Required attributes missing. Skipping record.")
                continue

            feedback_text = new_image["feedback"]["S"]
            record_id = new_image["id"]["S"]

            print(f"Processing record ID: {record_id}")

            prompt = f"""
            Analyze the following product feedback:

            "{feedback_text}"

            Return ONLY valid JSON in this format:
            {{
              "sentiment": "POSITIVE | NEGATIVE | NEUTRAL",
              "summary": "short summary"
            }}
            """

            response = bedrock.invoke_model(
                modelId=MODEL_ID,
                body=json.dumps({
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 300,
                    "messages": [
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ]
                })
            )

            result = json.loads(response["body"].read())
            raw_text = result["content"][0]["text"]

            print("Raw Bedrock response:", raw_text)

            # Attempt to extract JSON from model output
            try:
                ai_output = json.loads(raw_text.strip())
                sentiment = ai_output.get("sentiment", "UNKNOWN")
                summary = ai_output.get("summary", "N/A")
            except Exception:
                print("Failed to parse JSON. Storing raw response.")
                sentiment = "PARSE_ERROR"
                summary = raw_text

            # Update DynamoDB record
            table.update_item(
                Key={"id": record_id},
                UpdateExpression="SET sentiment = :s, summary = :sum",
                ExpressionAttributeValues={
                    ":s": sentiment,
                    ":sum": summary
                }
            )

            print(f"Successfully updated record: {record_id}")

        except Exception as e:
            print("Error processing record:", str(e))

    return {"statusCode": 200}

