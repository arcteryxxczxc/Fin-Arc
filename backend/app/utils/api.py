from flask import jsonify
import logging

logger = logging.getLogger(__name__)

def api_success(data=None, message=None, code=200):
    """Return successful API response"""
    response = {}
    if data is not None:
        if isinstance(data, dict):
            response.update(data)
        else:
            response["data"] = data
    if message:
        response["message"] = message
    return jsonify(response), code

def api_error(message, code=400, errors=None):
    """Return error API response"""
    response = {"error": message if isinstance(message, str) else "Error occurred"}
    if isinstance(message, dict):
        response.update(message)
    if errors:
        response["errors"] = errors
    return jsonify(response), code