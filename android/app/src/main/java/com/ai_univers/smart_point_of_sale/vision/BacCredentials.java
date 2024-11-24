package com.ai_univers.smart_point_of_sale.vision;

import java.io.Serializable;

public class BacCredentials implements Serializable {
    private String documentNumber;
    private String birthDate;
    private String expiredDate;

    public BacCredentials(String documentNumber, String birthDate, String expiredDate) {
        this.documentNumber = documentNumber;
        this.birthDate = birthDate;
        this.expiredDate = expiredDate;
    }

    public String getDocumentNumber() {
        return documentNumber;
    }

    public void setDocumentNumber(String documentNumber) {
        this.documentNumber = documentNumber;
    }

    public String getBirthDate() {
        return birthDate;
    }

    public void setBirthDate(String birthDate) {
        this.birthDate = birthDate;
    }

    public String getExpiredDate() {
        return expiredDate;
    }

    public void setExpiredDate(String expiredDate) {
        this.expiredDate = expiredDate;
    }
}
