<template>
  <el-dropdown trigger="click" @command="handleCommand">
    <span class="el-dropdown-link">
      {{ lang === 'zh-CN' ? '中文' : 'English' }}<i class="el-icon-arrow-down el-icon--right" />
    </span>
    <el-dropdown-menu slot="dropdown">
      <el-dropdown-item command="zh-CN">中文</el-dropdown-item>
      <el-dropdown-item command="en-US">English</el-dropdown-item>
    </el-dropdown-menu>
  </el-dropdown>
</template>
<script>
export default {
  name: 'ToggleLang',
  data() {
    return {
      lang: localStorage.getItem('LANGUAGE') || 'zh-CN',
    }
  },
  methods: {
    handleCommand(command) {
      this.lang = command
      this.$i18n.locale = command
      localStorage.setItem('LANGUAGE', command)
      window.location.reload()
    },
  },
}
</script>
<style lang="scss" scoped>
  .el-dropdown-link {
    cursor: pointer;
    color: #5a5e66;
    font-size: 14px;
  }
  .el-icon-arrow-down {
    font-size: 12px;
  }
</style>
