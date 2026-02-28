# ============================================================
# AI-POWERED ECOMMERCE EXECUTIVE ANALYST
# Gemini 2.5 Flash-Lite + MySQL
# Clean Board-Ready Reporting Format
# ============================================================

import os
import json
from datetime import datetime
from decimal import Decimal
from dotenv import load_dotenv
import mysql.connector
from google import genai

load_dotenv()


# ------------------------------------------------------------
# Utility: Convert Decimal to Float (JSON Safe)
# ------------------------------------------------------------

def convert_decimals(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    if isinstance(obj, dict):
        return {k: convert_decimals(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [convert_decimals(i) for i in obj]
    return obj


# ------------------------------------------------------------
# Database Connection
# ------------------------------------------------------------

def get_db_connection():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME")
    )


# ------------------------------------------------------------
# Fetch Advanced Business Metrics
# ------------------------------------------------------------

def fetch_business_metrics():
    conn = get_db_connection()
    cursor = conn.cursor()
    metrics = {}

    print("📊 Fetching advanced business metrics...")

    # Core Revenue
    cursor.execute("SELECT SUM(price + freight_value) FROM order_items;")
    total_revenue = cursor.fetchone()[0] or 0
    metrics["total_revenue"] = total_revenue

    cursor.execute("SELECT COUNT(DISTINCT order_id) FROM orders;")
    total_orders = cursor.fetchone()[0] or 0
    metrics["total_orders"] = total_orders

    cursor.execute("SELECT COUNT(DISTINCT customer_id) FROM customers;")
    total_customers = cursor.fetchone()[0] or 0
    metrics["total_customers"] = total_customers

    metrics["average_order_value"] = round(total_revenue / total_orders, 2) if total_orders else 0
    metrics["revenue_per_customer"] = round(total_revenue / total_customers, 2) if total_customers else 0

    # Repeat Customers
    cursor.execute("""
        SELECT COUNT(*) FROM (
            SELECT c.customer_unique_id
            FROM orders o
            JOIN customers c ON o.customer_id = c.customer_id
            GROUP BY c.customer_unique_id
            HAVING COUNT(o.order_id) > 1
        ) t;
    """)
    repeat = cursor.fetchone()[0] or 0
    metrics["repeat_customers"] = repeat
    metrics["repeat_rate_percent"] = round((repeat / total_customers) * 100, 2) if total_customers else 0

    # Late Delivery %
    cursor.execute("""
        SELECT COUNT(*) FROM orders
        WHERE order_delivered_customer_date > order_estimated_delivery_date;
    """)
    late = cursor.fetchone()[0] or 0

    cursor.execute("""
        SELECT COUNT(*) FROM orders
        WHERE order_status = 'delivered';
    """)
    delivered = cursor.fetchone()[0] or 0

    metrics["late_delivery_percent"] = round((late / delivered) * 100, 2) if delivered else 0

    # Cancellation Rate
    cursor.execute("SELECT COUNT(*) FROM orders WHERE order_status = 'canceled';")
    canceled = cursor.fetchone()[0] or 0
    metrics["cancellation_rate_percent"] = round((canceled / total_orders) * 100, 2) if total_orders else 0

    # Monthly Revenue (Last 12 Months)
    cursor.execute("""
        SELECT DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') AS month,
               ROUND(SUM(oi.price + oi.freight_value),2)
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        GROUP BY month
        ORDER BY month DESC
        LIMIT 12;
    """)
    metrics["monthly_revenue"] = [
        {"month": r[0], "revenue": r[1]}
        for r in cursor.fetchall()
    ]

    # Top 10 Categories
    cursor.execute("""
        SELECT p.product_category_name,
               ROUND(SUM(oi.price + oi.freight_value),2)
        FROM order_items oi
        JOIN products p ON oi.product_id = p.product_id
        GROUP BY p.product_category_name
        ORDER BY 2 DESC
        LIMIT 10;
    """)
    metrics["top_categories"] = [
        {"category": r[0], "revenue": r[1]}
        for r in cursor.fetchall()
    ]

    cursor.close()
    conn.close()

    print("✅ Metrics collected successfully\n")
    return metrics


# ------------------------------------------------------------
# Generate Clean Executive Report
# ------------------------------------------------------------

def generate_ai_report(metrics):

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY not found in .env file.")

    client = genai.Client(api_key=api_key)
    clean_metrics = convert_decimals(metrics)

    print("🤖 Generating board-level executive memorandum...\n")

    prompt = f"""
You are a senior McKinsey-level strategy consultant preparing a formal board memorandum.

IMPORTANT FORMAT RULES:
Do not use markdown.
Do not use hashtags.
Do not use asterisks.
Do not use bullet symbols.
Do not use decorative separators.
Write in clean executive business memo format.
Use capitalized section headers only.
Write in full paragraphs.
Be direct and analytical.
Use specific numbers from the data.
Avoid generic advice.

Structure the report exactly as follows:

EXECUTIVE SUMMARY

REVENUE INTELLIGENCE

CUSTOMER BEHAVIOR ANALYSIS

OPERATIONAL RISK ASSESSMENT

GROWTH OPPORTUNITIES

FIVE STRATEGIC RECOMMENDATIONS

RISK FLAGS FOR THE BOARD

Data:
{json.dumps(clean_metrics, indent=2)}
"""

    response = client.models.generate_content(
        model="gemini-2.5-flash-lite",
        contents=prompt
    )

    return response.text


# ------------------------------------------------------------
# Save Report
# ------------------------------------------------------------

def save_report(report):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"executive_report_{timestamp}.txt"

    with open(filename, "w", encoding="utf-8") as f:
        f.write("ECOMMERCE EXECUTIVE ANALYSIS REPORT\n")
        f.write(f"Generated: {datetime.now()}\n\n")
        f.write(report)

    print(f"💾 Report saved as {filename}")


# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

def main():
    print("\n🚀 ADVANCED ECOMMERCE AI EXECUTIVE ANALYST STARTED\n")

    try:
        metrics = fetch_business_metrics()
        report = generate_ai_report(metrics)

        print("========== EXECUTIVE REPORT ==========\n")
        print(report)

        save_report(report)

        print("\n✅ Board-ready report generated successfully.\n")

    except Exception as e:
        print(f"\n❌ ERROR: {e}\n")


if __name__ == "__main__":
    main()