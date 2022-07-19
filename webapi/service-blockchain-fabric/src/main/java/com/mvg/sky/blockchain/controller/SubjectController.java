package com.mvg.sky.blockchain.controller;

import com.mvg.sky.blockchain.dto.request.SubjectCreationDto;
import com.mvg.sky.blockchain.mapper.MapperUtil;
import com.mvg.sky.common.exception.RequestException;
import com.mvg.sky.repository.SubjectRepository;
import com.mvg.sky.repository.entity.SubjectEntity;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import javax.validation.Valid;
import java.net.URI;

@Slf4j
@RestController
@AllArgsConstructor
@Tag(name = "Subject API")
public class SubjectController {
    private final SubjectRepository subjectRepository;
    private final MapperUtil mapperUtil;

    @PostMapping("/subjects")
    public ResponseEntity<?> createSubjectApi(@Valid @RequestBody SubjectCreationDto subjectCreationDto) {
        try {
            SubjectEntity subjectEntity = new SubjectEntity();
            mapperUtil.createProfileFromDto(subjectCreationDto, subjectEntity);
            subjectEntity = subjectRepository.save(subjectEntity);

            return ResponseEntity.created(URI.create("/subjects" + subjectEntity.getId())).body(subjectEntity);
        }
        catch(Exception exception) {
            log.error("{}", exception.getMessage());
            throw new RequestException(exception.getMessage(), HttpStatus.UNAUTHORIZED);
        }
    }
}
