# Dockerfile for Fin-Arc Backend
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV FLASK_APP run.py

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create uploads directory
RUN mkdir -p app/uploads && chmod 777 app/uploads

# Copy project
COPY . .

# Expose port
EXPOSE 5000

# Run gunicorn in production, Flask development server otherwise
CMD ["sh", "-c", "if [ \"$FLASK_ENV\" = \"production\" ]; then gunicorn --bind 0.0.0.0:5000 \"run:app\"; else flask run --host=0.0.0.0; fi"]