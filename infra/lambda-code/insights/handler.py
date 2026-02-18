import boto3
from datetime import datetime, timedelta
from collections import defaultdict
import os
import json

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):

    product_id = event["queryStringParameters"]["product_id"]

    response = table.query(
        IndexName="product-created-index",
        KeyConditionExpression="product_id = :pid",
        ExpressionAttributeValues={":pid": product_id},
    )

    items = response.get("Items", [])

    total_reviews = len(items)
    total_rating = 0

    sentiment_counts = {"POSITIVE": 0, "NEGATIVE": 0, "NEUTRAL": 0}

    theme_counts = defaultdict(int)

    monthly_volume = defaultdict(int)
    monthly_sentiment = defaultdict(
        lambda: {"POSITIVE": 0, "NEGATIVE": 0, "NEUTRAL": 0}
    )

    six_months_ago = datetime.utcnow() - timedelta(days=180)

    for item in items:
        rating = int(item.get("rating", 0))
        sentiment = item.get("sentiment", "NEUTRAL")
        created_at = int(item["created_at"])

        dt = datetime.utcfromtimestamp(created_at)

        total_rating += rating
        sentiment_counts[sentiment] += 1

        # Monthly volume
        if dt >= six_months_ago:
            month_key = dt.strftime("%Y-%m")
            monthly_volume[month_key] += 1
            monthly_sentiment[month_key][sentiment] += 1

        # Themes (if exists)
        if "themes" in item:
            for theme in item["themes"]:
                theme_counts[theme] += 1

    avg_rating = round(total_rating / total_reviews, 2) if total_reviews else 0

    sentiment_percent = {
        k: round((v / total_reviews) * 100, 2) if total_reviews else 0
        for k, v in sentiment_counts.items()
    }

    sentiment_score_label = classify_sentiment(sentiment_percent["POSITIVE"])

    response_body = {
        "total_reviews": total_reviews,
        "avg_rating": avg_rating,
        "sentiment_distribution": sentiment_percent,
        "sentiment_score_label": sentiment_score_label,
        "review_volume": monthly_volume,
        "sentiment_trend": monthly_sentiment,
        "top_themes": theme_counts,
    }

    return {"statusCode": 200, "body": json.dumps(response_body)}


def classify_sentiment(positive_percent):
    if positive_percent >= 80:
        return "Excellent"
    elif positive_percent >= 60:
        return "Good"
    elif positive_percent >= 40:
        return "Needs Improvement"
    else:
        return "Bad"
