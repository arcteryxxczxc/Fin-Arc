import requests
import os
from datetime import datetime, timedelta
from app import db
from app.models import User

class ExchangeRate(db.Model):
    __tablename__ = 'exchange_rates'
    
    id = db.Column(db.Integer, primary_key=True)
    from_currency = db.Column(db.String(3), nullable=False)
    to_currency = db.Column(db.String(3), nullable=False)
    rate = db.Column(db.Float, nullable=False)
    last_updated = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    
    def save_to_db(self):
        db.session.add(self)
        db.session.commit()

class CurrencyService:
    """Service for fetching and converting currency rates with focus on UZS (Uzbekistani Som)"""
    
    # We'll use a free API for exchange rates
    # For this example, we'll use Open Exchange Rates (you'll need to register for a free API key)
    # or we can use ExchangeRate-API which has a free tier
    API_URL = "https://open.er-api.com/v6/latest/USD"
    
    @staticmethod
    def get_exchange_rate(from_currency, to_currency):
        """Get exchange rate between two currencies"""
        # Check if we have a recent rate in the database
        rate = ExchangeRate.query.filter_by(
            from_currency=from_currency, 
            to_currency=to_currency
        ).order_by(ExchangeRate.last_updated.desc()).first()
        
        # If rate exists and is less than 24 hours old, use it
        if rate and rate.last_updated > datetime.utcnow() - timedelta(hours=24):
            return rate.rate
        
        # Otherwise, fetch from API
        try:
            response = requests.get(CurrencyService.API_URL)
            data = response.json()
            
            if data.get('result') != 'success':
                raise Exception("API returned an error")
            
            # The API returns rates relative to USD
            rates = data.get('rates', {})
            
            # Convert rates to our desired currencies
            if from_currency == 'USD':
                new_rate = rates.get(to_currency, 1.0)
            elif to_currency == 'USD':
                new_rate = 1.0 / rates.get(from_currency, 1.0)
            else:
                # Convert between two non-USD currencies
                usd_to_from = rates.get(from_currency, 1.0)
                usd_to_to = rates.get(to_currency, 1.0)
                new_rate = usd_to_to / usd_to_from
            
            # Save to database
            exchange_rate = ExchangeRate(
                from_currency=from_currency,
                to_currency=to_currency,
                rate=new_rate,
                last_updated=datetime.utcnow()
            )
            exchange_rate.save_to_db()
            
            return new_rate
        except Exception as e:
            # If API fails, use the most recent rate if available
            if rate:
                return rate.rate
            # Otherwise, return 1.0 as fallback
            return 1.0
    
    @staticmethod
    def convert_amount(amount, from_currency, to_currency):
        """Convert an amount from one currency to another"""
        if from_currency == to_currency:
            return amount
        
        rate = CurrencyService.get_exchange_rate(from_currency, to_currency)
        return amount * rate
    
    @staticmethod
    def get_common_currencies():
        """Get list of common currencies with UZS first"""
        return [
            {"code": "UZS", "name": "Uzbekistan Sшm", "symbol": "сўм"},
            {"code": "USD", "name": "US Dollar", "symbol": "$"},
            {"code": "EUR", "name": "Euro", "symbol": "€"},
            {"code": "RUB", "name": "Russian Ruble", "symbol": "₽"},
            {"code": "KZT", "name": "Kazakhstan Tenge", "symbol": "₸"},
            {"code": "GBP", "name": "British Pound", "symbol": "£"},
            {"code": "JPY", "name": "Japanese Yen", "symbol": "¥"},
            {"code": "CNY", "name": "Chinese Yuan", "symbol": "¥"},
            {"code": "KRW", "name": "South Korean Won", "symbol": "₩"},
            {"code": "INR", "name": "Indian Rupee", "symbol": "₹"}
        ]