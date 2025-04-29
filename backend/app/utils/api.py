from flask import jsonify
import logging

logger = logging.getLogger(__name__)

def api_error(message, code=400, errors=None, log_error=True):
    """
    Standardized API error response
    
    Args:
        message: Error message string
        code: HTTP status code
        errors: Optional dict of field-specific errors
        log_error: Whether to log the error
        
    Returns:
        Flask response with JSON error
    """
    if log_error:
        logger.error(f"API Error ({code}): {message}")
    
    response = {"error": message}
    if errors:
        response["errors"] = errors
    
    return jsonify(response), code

def api_success(data=None, message=None, code=200):
    """
    Standardized API success response
    
    Args:
        data: Response data (optional)
        message: Success message (optional)
        code: HTTP status code
        
    Returns:
        Flask response with JSON data
    """
    response = {}
    
    if message:
        response["message"] = message
        
    if data is not None:
        if isinstance(data, dict) and not isinstance(data, list):
            # Merge data dictionary with response
            for key, value in data.items():
                response[key] = value
        else:
            # Use data as is
            response["data"] = data
    
    return jsonify(response), code