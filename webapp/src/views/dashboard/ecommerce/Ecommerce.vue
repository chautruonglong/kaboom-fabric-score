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
        >Collapse</b-button>
        <b-collapse
          v-model="isOpen"
        >
          <ecommerce-company-table :table-data="data.companyTable" />
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
      isOpen: true
    }
  },
  created() {
    // data
    this.$http.get('/ecommerce/data')
      .then(response => {
        this.data = response.data

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
