from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.services.currency import CurrencyService
from datetime import datetime
import logging

# Set up logging
logger = logging.getLogger(__name__)

@api_bp.route('/currencies/convert', methods=['GET'])
@jwt_required()
def convert_currency():
    """
    Convert amount from one currency to another
    
    Query parameters:
    - amount: Amount to convert (required)
    - from: Source currency code (default: UZS)
    - to: Target currency code (default: USD)
    """
    try:
        amount = request.args.get('amount', type=float)
        from_currency = request.args.get('from', default='UZS')
        to_currency = request.args.get('to', default='USD')
        
        if not amount:
            return jsonify({"error": "Amount is required"}), 400
        
        converted_amount = CurrencyService.convert_amount(amount, from_currency, to_currency)
        
        return jsonify({
            "original": {
                "amount": amount,
                "currency": from_currency
            },
            "converted": {
                "amount": converted_amount,
                "currency": to_currency
            },
            "rate": CurrencyService.get_exchange_rate(from_currency, to_currency)
        }), 200
    except Exception as e:
        logger.error(f"Error converting currency: {str(e)}")
        return jsonify({"error": f"Error converting currency: {str(e)}"}), 500

@api_bp.route('/currencies/rates', methods=['GET'])
@jwt_required()
def get_exchange_rates():
    """
    Get exchange rates for multiple currencies
    
    Query parameters:
    - base: Base currency code (default: UZS)
    - targets: Comma-separated list of target currencies (default: USD,EUR,RUB,KZT)
    """
    try:
        base_currency = request.args.get('base', default='UZS')
        target_currencies = request.args.get('targets', default='USD,EUR,RUB,KZT')
        
        targets = target_currencies.split(',')
        rates = {}
        
        for target in targets:
            rates[target] = CurrencyService.get_exchange_rate(base_currency, target)
        
        return jsonify({
            "base": base_currency,
            "rates": rates,
            "timestamp": datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        }), 200
    except Exception as e:
        logger.error(f"Error getting exchange rates: {str(e)}")
        return jsonify({"error": f"Error getting exchange rates: {str(e)}"}), 500

@api_bp.route('/currencies/list', methods=['GET'])
def get_currencies_list():
    """
    Get list of common currencies
    """
    try:
        return jsonify({
            "currencies": CurrencyService.get_common_currencies()
        }), 200
    except Exception as e:
        logger.error(f"Error getting currencies list: {str(e)}")
        return jsonify({"error": f"Error getting currencies list: {str(e)}"}), 500