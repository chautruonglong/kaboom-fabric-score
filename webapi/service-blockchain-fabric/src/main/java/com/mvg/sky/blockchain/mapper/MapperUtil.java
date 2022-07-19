package com.mvg.sky.blockchain.mapper;

import com.mvg.sky.blockchain.dto.request.SubjectCreationDto;
import com.mvg.sky.repository.entity.SubjectEntity;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

@Mapper(componentModel = "spring")
public interface MapperUtil {
    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void createProfileFromDto(SubjectCreationDto subjectCreationDto, @MappingTarget SubjectEntity subjectEntity);
}
