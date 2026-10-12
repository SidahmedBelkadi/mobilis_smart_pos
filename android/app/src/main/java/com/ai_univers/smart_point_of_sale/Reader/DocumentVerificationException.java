package com.ai_univers.smart_point_of_sale.Reader;

/**
 * The chip answered, but failed a cryptographic check: the document is not
 * genuine (emulated, cloned or altered). Must never be retried silently.
 */
public class DocumentVerificationException extends Exception {

    public DocumentVerificationException(String message) {
        super(message);
    }

    public DocumentVerificationException(String message, Throwable cause) {
        super(message, cause);
    }
}
