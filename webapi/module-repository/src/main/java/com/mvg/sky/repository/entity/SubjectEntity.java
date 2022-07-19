package com.mvg.sky.repository.entity;

import lombok.*;
import lombok.experimental.SuperBuilder;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Table;

@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
@ToString(callSuper = true)
@Entity
@Table(name = "subjects")
public class SubjectEntity extends BaseEntity {
    @Column(name = "name", nullable = false, columnDefinition = "text")
    private String name;

    @Column(name = "credits", nullable = false)
    private Integer credits;

    @Column(name = "bt", nullable = false)
    private Float bt;
    @Column(name = "wbt", nullable = false)
    private Float wbt;

    @Column(name = "bv", nullable = false)
    private Float bv;
    @Column(name = "wbv", nullable = false)
    private Float wbv;

    @Column(name = "cc", nullable = false)
    private Float cc;
    @Column(name = "wcc", nullable = false)
    private Float wcc;

    @Column(name = "ck", nullable = false)
    private Float ck;
    @Column(name = "wck", nullable = false)
    private Float wck;

    @Column(name = "gk", nullable = false)
    private Float gk;
    @Column(name = "wgk", nullable = false)
    private Float wgk;

    @Column(name = "lt", nullable = false)
    private Float lt;
    @Column(name = "wlt", nullable = false)
    private Float wlt;

    @Column(name = "qt", nullable = false)
    private Float qt;
    @Column(name = "wqt", nullable = false)
    private Float wqt;

    @Column(name = "th", nullable = false)
    private Float th;
    @Column(name = "wth", nullable = false)
    private Float wth;

    @Column(name = "score", nullable = false)
    private Float score;

    @Column(name = "grade", nullable = false, columnDefinition = "text")
    private String grade;

}
