package com.mvg.sky.realtime.dto.payload;

import com.mvg.sky.realtime.enumeration.PayloadEnumeration;
import lombok.Data;

@Data
public class OutputPayload {
    private PayloadEnumeration command;

    private Object data;
}
