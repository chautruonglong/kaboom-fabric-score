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

    @Column(name = "bt")
    private Float bt;
    @Column(name = "wbt")
    private Float wbt;

    @Column(name = "bv")
    private Float bv;
    @Column(name = "wbv")
    private Float wbv;

    @Column(name = "cc")
    private Float cc;
    @Column(name = "wcc")
    private Float wcc;

    @Column(name = "ck")
    private Float ck;
    @Column(name = "wck")
    private Float wck;

    @Column(name = "gk")
    private Float gk;
    @Column(name = "wgk")
    private Float wgk;

    @Column(name = "lt")
    private Float lt;
    @Column(name = "wlt")
    private Float wlt;

    @Column(name = "qt")
    private Float qt;
    @Column(name = "wqt")
    private Float wqt;

    @Column(name = "th")
    private Float th;
    @Column(name = "wth")
    private Float wth;

    @Column(name = "score")
    private Float score;

    @Column(name = "grade", columnDefinition = "text")
    private String grade;

    @Column(name = "term", columnDefinition = "text")
    private String term;
}
