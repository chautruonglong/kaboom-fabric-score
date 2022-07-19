package com.mvg.sky.repository;

import com.mvg.sky.repository.entity.SubjectEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface SubjectRepository extends JpaRepository<SubjectEntity, UUID> {
}
