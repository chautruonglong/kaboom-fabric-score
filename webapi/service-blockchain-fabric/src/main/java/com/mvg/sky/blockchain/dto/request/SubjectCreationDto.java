package com.mvg.sky.blockchain.dto.request;

import lombok.Data;

import javax.persistence.Column;

@Data
public class SubjectCreationDto {
    private String name;

    private Integer credits;

    private Float bt;
    private Float wbt;

    private Float bv;
    private Float wbv;

    private Float cc;
    private Float wcc;

    private Float ck;
    private Float wck;

    private Float gk;
    private Float wgk;

    private Float lt;
    private Float wlt;

    private Float qt;
    private Float wqt;

    private Float th;
    private Float wth;

    private Float score;

    private String grade;

    private String term;
}
