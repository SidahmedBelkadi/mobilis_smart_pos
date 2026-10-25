package com.ai_univers.smart_point_of_sale.Reader;

/**
 * The chip refused the BAC keys: the MRZ data (document number, birth or expiry
 * date) does not match this document. Presenting the same card again cannot help.
 */
public class BacFailedException extends Exception {

    public BacFailedException(Throwable cause) {
        super("BAC refused by the chip", cause);
    }
}
