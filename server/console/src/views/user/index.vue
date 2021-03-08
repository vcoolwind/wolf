<template>
  <div class="app-container">
    <div class="filter-container">
      <el-input
        v-model="listQuery.key"
        :placeholder="$t('m.userSearchPlaceholder')"
        style="width: 200px;"
        class="filter-item"
        maxlength="32"
        clearable
        @keyup.enter.native="handleFilter"
      />
      <el-button class="filter-item" type="primary" icon="el-icon-search" @click="handleFilter">
        {{ $t('m.search') }}
      </el-button>
      <el-button class="filter-item" type="primary" @click="handleAdd">{{ $t('m.add') }}</el-button>
    </div>
    <el-table
      :data="users"
      style="margin-top:30px;"
      :row-class-name="tableRowClassName"
      border
      fit
      highlight-current-row
    >
      <el-table-column align="center" label="ID" min-width="5" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.id }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.userName')" min-width="20" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.username }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.nickName')" min-width="20" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.nickname }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.userManager')" min-width="10" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.manager }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.appId')" min-width="25" show-overflow-tooltip prop="appIDs" :formatter="appIdsFormat" />
      <el-table-column align="center" :label="$t('m.userStatus')" min-width="10" prop="status" :formatter="userStatusFormat" />
      <el-table-column align="center" :label="$t('m.appTableCreateTime')" min-width="18" show-overflow-tooltip prop="createTime" :formatter="unixtimeFormat" />
      <el-table-column align="center" :label="$t('m.userPermissions')" min-width="15">
        <template slot-scope="scope">
          <role-detail :user="scope.row" />
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.appTableCreateOperations')" min-width="25">
        <template slot-scope="scope">
          <el-tooltip class="item" effect="dark" content="Reset password" placement="top">
            <el-button type="primary" size="small" @click="handleReset(scope)">{{ $t('m.reset') }}</el-button>
          </el-tooltip>
          <el-button type="primary" size="small" @click="handleEdit(scope)">{{ $t('m.edit') }}</el-button>
          <el-button type="danger" size="small" @click="handleDelete(scope)">{{ $t('m.delete') }}</el-button>
        </template>
      </el-table-column>
    </el-table>
    <div class="pagination pagination-center">
      <pagination v-show="total>0" :total="total" :page.sync="listQuery.page" :limit.sync="listQuery.limit" @pagination="listUsers" />
    </div>
    <el-dialog :visible.sync="dialogVisible" :title="dialogType==='edit'? $t('m.edit') : $t('m.add')" custom-class="rbac-edit-dialog">
      <el-form ref="user" :model="user" :rules="rules" label-width="120px" label-position="left">
        <el-form-item :label="$t('m.userName')" prop="username">
          <el-input v-model="user.username" :placeholder="$t('m.userName')" />
        </el-form-item>
        <el-form-item :label="$t('m.nickName')" prop="nickname">
          <el-input v-model="user.nickname" :placeholder="$t('m.nickName')" />
        </el-form-item>
        <el-form-item :label="$t('m.email')" prop="email">
          <el-input v-model="user.email" :placeholder="$t('m.email')" />
        </el-form-item>
        <el-form-item :label="$t('m.tel')" prop="tel">
          <el-input v-model="user.tel" :placeholder="$t('m.tel')" />
        </el-form-item>
        <el-form-item :label="$t('m.appId')" prop="appIDs">
          <el-select v-model="user.appIDs" multiple filterable :placeholder="$t('m.appId')" style="display: block">
            <el-option v-for="application in applications" :key="application.id" :label="application.name" :value="application.id" />
          </el-select>
        </el-form-item>
        <el-form-item :label="$t('m.userManager')" prop="manager">
          <el-radio-group v-model="user.manager" size="small">
            <el-radio-button label="super" />
            <el-radio-button label="admin" />
            <el-radio-button label="none" />
          </el-radio-group>
        </el-form-item>
        <el-form-item :label="$t('m.userStatus')" prop="status">
          <el-radio-group v-model="user.status" size="small">
            <el-radio-button label="0">{{ $t('m.normal') }}</el-radio-button>
            <el-radio-button label="-1">{{ $t('m.disabled') }}</el-radio-button>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <div style="text-align:right;">
        <el-button type="danger" @click="dialogVisible=false">{{ $t('m.cancel') }}</el-button>
        <el-button type="primary" @click="validateAndSubmit('user')">{{ $t("m.confirm") }}</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import { deepClone } from '@/utils'
import { listUsers, addUser, deleteUser, updateUser, checkUsernameExist, resetPwd } from '@/api/user'

import Pagination from '@/components/Pagination' // secondary package based on el-pagination
import RoleDetail from '@/views/user/roleDetail'

const defaultUser = {
  username: '',
  nickname: '',
  email: '',
  tel: '',
  appIDs: [],
  manager: '',
  routes: [],
  status: 0,
}

export default {
  name: 'User',
  components: { Pagination, RoleDetail },
  props: {},
  data() {
    return {
      user: Object.assign({}, defaultUser),
      routes: [],
      users: [],
      total: 0,
      listQuery: {
        page: 1,
        limit: 10,
        key: undefined,
        sort: '-id',
      },
      dialogVisible: false,
      dialogType: 'new',
      checkStrictly: false,
      defaultProps: {
        children: 'children',
        label: 'title',
      },
      appIdsRules: [],
      // rules: {
      // appIDs: [
      //   { required: true, message: 'Please select a management application.', trigger: ['blur', 'change'] },
      // ],
      // },
    }
  },
  computed: {
    ...mapGetters([
      'applications',
    ]),
    rules() {
      return {
        username: [
          { required: true, message: this.$t('m.userNameWarnMsg'), trigger: ['blur', 'change'] },
          { min: 2, max: 32, message: this.$t('m.lengthWarn'), trigger: ['blur', 'change'] },
          { pattern: /^[a-zA-Z0-9_-]*$/, message: this.$t('m.inputOnly'), trigger: ['blur', 'change'] },
          { validator: this.validateUsername, trigger: ['blur', 'change'] },
        ],
        nickname: [
          { required: true, message: this.$t('m.nickNameWarnMsg'), trigger: ['blur', 'change'] },
          { min: 2, max: 32, message: this.$t('m.lengthWarn'), trigger: ['blur', 'change'] },
        ],
        email: [{ required: true, type: 'email', message: this.$t('m.emailWarnMsg'), trigger: ['blur', 'change'] }],
        tel: [
          { required: true, pattern: /^\d{6,12}$/, message: this.$t('m.phoneWarnMsg'), trigger: ['blur', 'change'] },
        ],
        appIDs: this.appIdsRules,
      }
    },
  },
  watch: {
    'user.manager': function(val) {
      if (val === 'admin') {
        this.appIdsRules = [
          { required: true, message: this.$t('m.manageAppWarnMsg'), trigger: ['blur', 'change'] },
        ]
        if (this.dialogVisible) {
          setTimeout(() => {
            this.$refs.user.validateField('appIDs')
          }, 0)
        }
      } else {
        this.appIdsRules = []
        if (this.dialogVisible) {
          setTimeout(() => {
            this.$refs.user.clearValidate(['appIDs'])
          }, 0)
        }
      }
    },
  },
  created() {
    this.listUsers()
  },
  mounted() {},
  methods: {
    tableRowClassName({ row, rowIndex }) {
      if (row.status === -1) {
        return 'disabled-row'
      }
      return ''
    },
    appIdsFormat(row, column, cellValue, index) {
      if (cellValue == null || cellValue === '') {
        return ''
      }
      const values = cellValue.join('|')
      return values
    },

    async validateUsername(rule, value, callback) {
      const res = await checkUsernameExist(value, this.user.id)
      if (res.ok && res.exist) {
        callback(new Error(`${this.$t('m.userName')} '${value}' ${this.$t('m.alreadyExist')}`))
      } else {
        callback()
      }
    },

    async listUsers() {
      const res = await listUsers(this.listQuery)
      if (res.ok) {
        this.total = res.data.total
        this.users = res.data.userInfos
      }
    },
    handleFilter() {
      this.listQuery.page = 1
      this.listUsers()
    },
    handleAdd() {
      this.user = Object.assign({}, defaultUser)
      this.dialogType = 'new'
      this.dialogVisible = true
    },
    handleEdit(scope) {
      this.dialogType = 'edit'
      this.dialogVisible = true
      this.checkStrictly = true
      this.user = deepClone(scope.row)
    },
    handleReset({ $index, row }) {
      this.$confirm(this.$t('m.resetPwdMsg'), this.$t('m.warningPopTitle'), {
        confirmButtonText: this.$t('m.confirm'),
        cancelButtonText: this.$t('m.cancel'),
        type: 'warning',
      })
        .then(async() => {
          const res = await resetPwd(row.id)
          if (res.ok) {
            const password = res.data.password
            this.$notify({
              title: this.$t('m.successTitle'),
              dangerouslyUseHTMLString: true,
              message: `
                <div>${this.$t('m.resetPwdSuccessMsg')} ${password}</div>
                <div>${this.$t('m.resetPwdSuccessMsg1')} </div>
              `,
              type: 'success',
              duration: 0,
            })
          }
        })
        .catch(err => { console.error(err) })
    },
    handleDelete({ $index, row }) {
      this.$confirm(this.$t('m.deleteUserWarningMsg'), this.$t('m.warningPopTitle'), {
        confirmButtonText: this.$t('m.confirm'),
        cancelButtonText: this.$t('m.cancel'),
        type: 'warning',
      })
        .then(async() => {
          const res = await deleteUser(row.id)
          if (res.ok) {
            this.listUsers()
            this.$message({
              type: 'success',
              message: this.$t('m.deleteSuccessMsg'),
            })
          }
        })
        .catch(err => { console.error(err) })
    },

    async validateAndSubmit(formName) {
      this.$refs[formName].validate(async(valid) => {
        if (valid) {
          await this.submitUser()
        } else {
          return false
        }
      })
    },

    async submitUser() {
      const isEdit = this.dialogType === 'edit'
      if (isEdit) {
        await updateUser(this.user.id, this.user)
        this.listUsers()
        const { username } = this.user
        this.dialogVisible = false
        this.$notify({
          title: this.$t('m.successTitle'),
          dangerouslyUseHTMLString: true,
          message: `
            <div>${this.$t('m.alterUserMsg')} ${username} ${this.$t('m.successTitle')}.</div>
          `,
          type: 'success',
        })
      } else {
        const { data } = await addUser(this.user)
        this.user.id = data.userInfo.id
        const password = data.password
        const { username } = this.user
        this.listUsers()
        this.dialogVisible = false
        this.$notify({
          title: this.$t('m.successTitle'),
          dangerouslyUseHTMLString: true,
          message: `
            <div>${this.$t('m.userName')}: ${username}</div>
            <div>${this.$t('m.passWord')}: ${password}</div>
            <div>${this.$t('m.resetPwdSuccessMsg1')}</div>
          `,
          type: 'success',
          duration: 0,
        })
      }
    },
  },
}
</script>

<style lang="scss">
  .el-table .disabled-row {
    background: #ededef;
    color: #9e1433;
  }
</style>
