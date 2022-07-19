<template>
  <section id="dashboard-ecommerce">
    <b-row class="match-height">
      <b-col
        xl="4"
        md="6"
      >
        <ecommerce-medal :data="data.congratulations" />
      </b-col>
      <b-col
        xl="8"
        md="6"
      >
        <ecommerce-statistics :data="data.statisticsItems" />
      </b-col>
    </b-row>

    <b-row class="match-height">
      <b-col>
        <b-button
          v-ripple.400="'rgba(255, 255, 255, 0.15)'"
          variant="primary"
          :class="{ 'mb-2': !isOpen }"
          @click="isOpen = !isOpen"
        >Term 1</b-button>
        <b-collapse
          v-model="isOpen"
        >
          <ecommerce-company-table :table-data="data.companyTable" />
        </b-collapse>
      </b-col>
    </b-row>

    <b-row class="match-height">
      <b-col>
        <b-button
          v-ripple.400="'rgba(255, 255, 255, 0.15)'"
          variant="primary"
          :class="{ 'mb-2': !isOpen1 }"
          @click="isOpen1 = !isOpen1"
        >Term 2</b-button>
        <b-collapse
          v-model="isOpen1"
        >
          <ecommerce-company-table :table-data="data.companyTable1" />
        </b-collapse>
      </b-col>
    </b-row>

    <b-row class="match-height">
      <b-col>
        <b-button
          v-ripple.400="'rgba(255, 255, 255, 0.15)'"
          variant="primary"
          :class="{ 'mb-2': !isOpen2 }"
          @click="isOpen2 = !isOpen2"
        >Term 3</b-button>
        <b-collapse
          v-model="isOpen2"
        >
          <ecommerce-company-table :table-data="data.companyTable2" />
        </b-collapse>
      </b-col>
    </b-row>
  </section>
</template>

<script>
import { BRow, BCol, BCollapse, BButton } from 'bootstrap-vue'

import { getUserData } from '@/auth/utils'
import EcommerceMedal from './EcommerceMedal.vue'
import EcommerceStatistics from './EcommerceStatistics.vue'
import EcommerceCompanyTable from './EcommerceCompanyTable.vue'

export default {
  components: {
    BRow,
    BCol,
    BCollapse,
    BButton,

    EcommerceMedal,
    EcommerceStatistics,
    EcommerceCompanyTable,
  },
  data() {
    return {
      data: {},
      isOpen: true,
      isOpen1: true,
      isOpen2: true
    }
  },
  created() {
    this.$http.get('/ecommerce/data')
      .then(response => {
        this.data = response.data
        this.data.companyTable = [
          { subject: 'Pháp luật đại cương', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Hóa học', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Đồ án công nghệ phần mềm', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Lập trình hướng đối tượng', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Giải tích 1', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Giải tích 2', credits: 2, bt: null, bv: 10, cc: null, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Pháp luật đại cương 2', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Hệ thống nhúng', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Lạp trình song song', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Vi điều khiển', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'}
        ]

        this.data.companyTable1 = [
          { subject: 'Pháp luật đại cương', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Hóa học', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Đồ án công nghệ phần mềm', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Lập trình hướng đối tượng', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Giải tích 1', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Giải tích 2', credits: 2, bt: null, bv: 10, cc: null, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Pháp luật đại cương 2', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Hệ thống nhúng', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Lạp trình song song', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Vi điều khiển', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'}
        ]

        this.data.companyTable2 = [
          { subject: 'Pháp luật đại cương', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Hóa học', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Đồ án công nghệ phần mềm', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Lập trình hướng đối tượng', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Giải tích 1', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Giải tích 2', credits: 2, bt: null, bv: 10, cc: null, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Pháp luật đại cương 2', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Hệ thống nhúng', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Lạp trình song song', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'},
          { subject: 'Vi điều khiển', credits: 2, bt: null, bv: null, cc: 8, ck: 8.5, gk: 9, lt: null, qt: null, score: 9, grade: 'A+'}
        ]

        // ? Your API will return name of logged in user or you might just directly get name of logged in user
        // ? This is just for demo purpose
        const userData = getUserData()
        this.data.congratulations.name = userData.fullName.split(' ')[0] || userData.username
      })
  },
}
</script>

<style lang="scss">
@import '@core/scss/vue/pages/dashboard-ecommerce.scss';
@import '@core/scss/vue/libs/chart-apex.scss';
</style>
