import Vue from 'vue'

import Cookies from 'js-cookie'

import 'normalize.css/normalize.css' // a modern alternative to CSS resets

import Element from 'element-ui'

import localeEN from 'element-ui/lib/locale/lang/en'
import localeCN from 'element-ui/lib/locale/lang/zh-CN'
// import VueI18n from 'vue-i18n'
import i18n from '@/common/lang/index.js'
import './styles/element-variables.scss'

import '@/styles/index.scss' // global css

import App from './App'
import store from './store'
import router from './router'

import './icons' // icon
import './permission' // permission control

import * as filters from './filters' // global filters

import { formatterMixin } from './utils/formatter'
Vue.mixin(formatterMixin)

Vue.use(Element, {
  size: Cookies.get('size') || 'medium', // set element-ui default size
  locale: localStorage.getItem('LANGUAGE') === 'en-US' ? localeEN : localeCN,
})

Vue.use(Element, {
  i18n: (key, value) => i18n.t(key, value),
})
// Vue.use(VueI18n)
// const i18n = new VueI18n({
//   locale: 'zh-CN', // 语言标识
//   // this.$i18n.locale // 通过切换locale的值来实现语言切换
//   messages: {
//     'zh-CN': require('./common/lang/zh'), // 中文语言包
//     'en-US': require('./common/lang/en'), // 英文语言包
//   },
// })

// register global utility filters
Object.keys(filters).forEach(key => {
  Vue.filter(key, filters[key])
})

Vue.config.productionTip = false

new Vue({
  el: '#app',
  i18n,
  router,
  store,
  render: h => h(App),
})
