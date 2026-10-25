package com.ai_univers.smart_point_of_sale.Reader;

/**
 * Progress of a chip read, shown to the user while the document is on the phone.
 * Called on the NFC reader thread.
 */
public interface NfcProgressListener {

    /** Unlocking the chip (BAC). */
    String STEP_AUTH = "AUTH";
    /** Reading the data groups. */
    String STEP_READ = "READ";
    /** Checking that the chip is genuine (Active Authentication). */
    String STEP_VERIFY = "VERIFY";

    /** @param percent 0..100, never decreasing within one attempt */
    void onProgress(int percent, String step);
}
