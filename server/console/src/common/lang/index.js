import Vue from 'vue'
import VueI18n from 'vue-i18n'

Vue.use(VueI18n)

// 国际化
const LANGUAGE = localStorage.getItem('LANGUAGE') || 'zh-CN'
const i18n = new VueI18n({
  locale: LANGUAGE, // set locale
  messages: {
    'zh-CN': require('./zh.js'), // 中文语言包
    'en-US': require('./en.js'), // 英文语言包
  },
})

export default i18n
