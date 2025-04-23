from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.services.currency import CurrencyService
from datetime import datetime

@api_bp.route('/currencies/convert', methods=['GET'])
@jwt_required()
def convert_currency():
    amount = request.args.get('amount', type=float)
    from_currency = request.args.get('from', default='UZS')
    to_currency = request.args.get('to', default='USD')
    
    if not amount:
        return jsonify({"msg": "Amount is required"}), 400
    
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

@api_bp.route('/currencies/rates', methods=['GET'])
@jwt_required()
def get_exchange_rates():
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

@api_bp.route('/currencies/list', methods=['GET'])
def get_currencies_list():
    """Get list of common currencies"""
    return jsonify({
        "currencies": CurrencyService.get_common_currencies()
    }), 200