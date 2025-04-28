/**
 * Main JavaScript file for Fin-Arc Personal Finance Application
 * Provides common functionality for the application
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize Bootstrap tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl)
    });
    
    // Initialize Bootstrap popovers
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
    var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl)
    });
    
    // Auto-hide alerts after 5 seconds
    setTimeout(function() {
        var alerts = document.querySelectorAll('.alert:not(.alert-permanent)');
        alerts.forEach(function(alert) {
            var bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        });
    }, 5000);
    
    // Format currency inputs
    var currencyInputs = document.querySelectorAll('.currency-input');
    currencyInputs.forEach(function(input) {
        input.addEventListener('input', formatCurrency);
    });
    
    // Format date inputs in user's locale
    var dateElements = document.querySelectorAll('.format-date');
    dateElements.forEach(function(element) {
        var dateStr = element.textContent;
        if (dateStr) {
            var date = new Date(dateStr);
            if (!isNaN(date)) {
                element.textContent = formatDate(date);
            }
        }
    });
    
    // Confirmation dialogs for delete actions
    var deleteButtons = document.querySelectorAll('[data-confirm]');
    deleteButtons.forEach(function(button) {
        button.addEventListener('click', function(e) {
            var message = this.getAttribute('data-confirm') || 'Are you sure?';
            if (!confirm(message)) {
                e.preventDefault();
            }
        });
    });
    
    // Toggle password visibility
    var passwordToggles = document.querySelectorAll('.password-toggle');
    passwordToggles.forEach(function(toggle) {
        toggle.addEventListener('click', togglePasswordVisibility);
    });
});

/**
 * Formats a number as currency
 * @param {Event} e - Input event
 */
function formatCurrency(e) {
    // Get input value and remove non-digit characters except decimal point
    var input = e.target;
    var value = input.value.replace(/[^\d.]/g, '');
    
    // Validate decimal places
    var parts = value.split('.');
    if (parts.length > 2) {
        // More than one decimal point, keep only the first two parts
        value = parts[0] + '.' + parts[1];
    }
    
    if (parts.length > 1) {
        // Limit to 2 decimal places
        value = parts[0] + '.' + parts[1].substring(0, 2);
    }
    
    // Convert to number and format
    var number = parseFloat(value);
    if (!isNaN(number)) {
        input.value = number.toLocaleString('en-US', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    } else {
        input.value = '';
    }
}

/**
 * Formats a date in the user's locale
 * @param {Date} date - Date object to format
 * @returns {string} Formatted date string
 */
function formatDate(date) {
    return date.toLocaleDateString(undefined, {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
}

/**
 * Toggles password visibility
 * @param {Event} e - Click event
 */
function togglePasswordVisibility(e) {
    var button = e.target.closest('button');
    var inputId = button.getAttribute('data-password-toggle');
    var input = document.getElementById(inputId);
    var icon = button.querySelector('i');
    
    if (input.type === 'password') {
        input.type = 'text';
        icon.classList.remove('fa-eye');
        icon.classList.add('fa-eye-slash');
    } else {
        input.type = 'password';
        icon.classList.remove('fa-eye-slash');
        icon.classList.add('fa-eye');
    }
}

/**
 * Creates a chart using Chart.js
 * @param {string} elementId - ID of the canvas element
 * @param {string} type - Chart type (pie, bar, line, etc.)
 * @param {Object} data - Chart data
 * @param {Object} options - Chart options
 */
function createChart(elementId, type, data, options) {
    var ctx = document.getElementById(elementId).getContext('2d');
    
    // Set default options
    var defaultOptions = {
        responsive: true,
        maintainAspectRatio: false
    };
    
    // Merge default options with provided options
    var chartOptions = Object.assign({}, defaultOptions, options);
    
    // Create and return the chart
    return new Chart(ctx, {
        type: type,
        data: data,
        options: chartOptions
    });
}

/**
 * Formats a number as currency for display
 * @param {number} amount - Amount to format
 * @param {string} currency - Currency code (default: USD)
 * @returns {string} Formatted currency string
 */
function formatCurrencyDisplay(amount, currency = 'USD') {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currency
    }).format(amount);
}

/**
 * Handles AJAX form submission
 * @param {string} formId - ID of the form to submit
 * @param {Function} successCallback - Function to call on success
 * @param {Function} errorCallback - Function to call on error
 */
function submitFormAjax(formId, successCallback, errorCallback) {
    var form = document.getElementById(formId);
    var url = form.action;
    var method = form.method;
    var formData = new FormData(form);
    
    fetch(url, {
        method: method,
        body: formData,
        headers: {
            'X-Requested-With': 'XMLHttpRequest'
        },
        credentials: 'same-origin'
    })
    .then(function(response) {
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.json();
    })
    .then(function(data) {
        if (successCallback && typeof successCallback === 'function') {
            successCallback(data);
        }
    })
    .catch(function(error) {
        if (errorCallback && typeof errorCallback === 'function') {
            errorCallback(error);
        } else {
            console.error('Error:', error);
        }
    });
}

/**
 * Shows a notification toast
 * @param {string} message - Message to display
 * @param {string} type - Alert type (success, danger, warning, info)
 * @param {number} duration - Duration in milliseconds
 */
function showNotification(message, type = 'info', duration = 3000) {
    // Create toast container if it doesn't exist
    var toastContainer = document.getElementById('toast-container');
    if (!toastContainer) {
        toastContainer = document.createElement('div');
        toastContainer.id = 'toast-container';
        toastContainer.className = 'toast-container position-fixed bottom-0 end-0 p-3';
        document.body.appendChild(toastContainer);
    }
    
    // Create toast element
    var toastId = 'toast-' + Date.now();
    var toast = document.createElement('div');
    toast.id = toastId;
    toast.className = 'toast';
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'assertive');
    toast.setAttribute('aria-atomic', 'true');
    
    // Set toast content
    toast.innerHTML = `
        <div class="toast-header bg-${type} text-white">
            <strong class="me-auto">Fin-Arc</strong>
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
        <div class="toast-body">
            ${message}
        </div>
    `;
    
    // Add toast to container
    toastContainer.appendChild(toast);
    
    // Show toast
    var bsToast = new bootstrap.Toast(toast, {
        delay: duration
    });
    bsToast.show();
    
    // Remove toast from DOM after it's hidden
    toast.addEventListener('hidden.bs.toast', function() {
        toast.remove();
    });
}