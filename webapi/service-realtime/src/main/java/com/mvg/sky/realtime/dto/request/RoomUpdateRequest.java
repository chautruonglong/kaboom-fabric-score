package com.mvg.sky.realtime.dto.request;

import com.mvg.sky.common.enumeration.RoomEnumeration;
import lombok.Data;

@Data
public class RoomUpdateRequest {
    private String name;

    private String description;

    private RoomEnumeration type;
}
