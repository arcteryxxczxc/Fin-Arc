from app import create_app

app = create_app()

if __name__ == "__main__":
    # Run the app with threading for better performance
    app.run(debug=True, host='0.0.0.0', port=8111, threaded=True)