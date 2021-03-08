<template>
  <div class="app-container">

    <div class="filter-container">
      <div class="filter-item">{{ $t('m.application') }}:</div>
      <current-app class="current-app filter-item" />
      <el-input
        v-model="listQuery.key"
        :placeholder="$t('m.roleSearchPlaceholder')"
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

    <el-table :data="roles" style="margin-top:30px; " border>
      <el-table-column align="center" label="ID" min-width="25" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.id }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.roleName')" min-width="25" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.name }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.description')" min-width="40" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.description }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.userApp')" min-width="20" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.appID }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.userPermissions')" min-width="20" show-overflow-tooltip>
        <template slot-scope="scope">
          <el-button type="primary" size="small" @click="handleView(scope)">{{ $t('m.show') }}</el-button>
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.appTableCreateTime')" min-width="20" show-overflow-tooltip prop="createTime" :formatter="unixtimeFormat" />
      <el-table-column align="center" :label="$t('m.appTableCreateOperations')" min-width="20" show-overflow-tooltip>
        <template slot-scope="scope">
          <el-button type="primary" size="small" @click="handleEdit(scope)">{{ $t('m.edit') }}</el-button>
          <el-button type="danger" size="small" @click="handleDelete(scope)">{{ $t('m.delete') }}</el-button>
        </template>
      </el-table-column>
    </el-table>
    <div class="pagination pagination-center">
      <pagination v-show="total>0" :total="total" :page.sync="listQuery.page" :limit.sync="listQuery.limit" @pagination="listRoles" />
    </div>

    <el-dialog :visible.sync="dialogVisible" :title="dialogTitle" custom-class="rbac-edit-dialog">
      <el-form ref="role" :model="role" :rules="rules" label-width="120px" label-position="left">
        <el-form-item label="ID" prop="id">
          <el-input
            v-model="role.id"
            placeholder="ID"
            :readonly="dialogType==='edit'||dialogType==='view'"
          />
        </el-form-item>
        <el-form-item :label="$t('m.roleName')" prop="name">
          <el-input
            v-model="role.name"
            :placeholder="$t('m.roleName')"
            minlength="5"
            maxlength="64"
            show-word-limit
            :readonly="inputReadonly"
          />
        </el-form-item>
        <el-form-item :label="$t('m.description')" prop="description">
          <el-input
            v-model="role.description"
            :placeholder="$t('m.description')"
            maxlength="256"
            show-word-limit
            :readonly="inputReadonly"
          />
        </el-form-item>
        <el-form-item :label="$t('m.userApp')" prop="appID" :readonly="inputReadonly">
          <el-select v-model="role.appID" placeholder="$t('m.userApp')" size="small" style="display: block" />
        </el-form-item>
        <el-form-item :label="$t('m.userPermissions')" prop="permIDs">
          <permission-select :value.sync="role.permIDs" multiple :readonly="dialogType==='view'" />
        </el-form-item>
      </el-form>
      <div style="text-align:right;">
        <el-button type="danger" @click="dialogVisible=false">{{ $t('m.cancel') }}</el-button>
        <el-button v-if="dialogType!=='view'" type="primary" @click="validateAndSubmit('role');">{{ $t('m.confirm') }}</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
// import path from 'path'
import CurrentApp from '@/components/CurrentApp'
import PermissionSelect from '@/components/PermissionSelect'

import { deepClone } from '@/utils'
import { listRoles, addRole, deleteRole, updateRole, checkRoleIDExist, checkRoleNameExist } from '@/api/role'

import Pagination from '@/components/Pagination' // secondary package based on el-pagination

const defaultRole = {
  id: '',
  appID: '',
  name: '',
  description: '',
  permIDs: [],
}

export default {
  name: 'Role',
  components: { CurrentApp, Pagination, PermissionSelect },
  props: {},
  data() {
    return {
      role: Object.assign({}, defaultRole),
      routes: [],
      roles: [],
      total: 0,
      listQuery: {
        page: 1,
        limit: 10,
        key: undefined,
        appID: null,
        sort: '-createTime',
      },
      dialogVisible: false,
      dialogType: 'new',
      checkStrictly: false,
      defaultProps: {
        children: 'children',
        label: 'title',
      },

      rules: {
        id: [
          { required: true, message: this.$t('m.roleIdWarnMsg'), trigger: ['blur', 'change'] },
          { min: 2, max: 32, message: this.$t('m.lengthWarn'), trigger: ['blur', 'change'] },
          { pattern: /^[a-zA-Z0-9_-]*$/, message: this.$t('m.roleIdInputOnly'), trigger: ['blur', 'change'] },
          { validator: this.validateRoleId, trigger: ['blur', 'change'] },
        ],
        name: [
          { required: true, message: this.$t('m.roleNameWarnMsg'), trigger: ['blur', 'change'] },
          { min: 2, max: 32, message: this.$t('m.lengthWarn'), trigger: ['blur', 'change'] },
          { validator: this.validateRoleName, trigger: ['blur', 'change'] },
        ],
      },
    }
  },
  computed: {
    currentApp: function() {
      return this.$store.getters.currentApp
    },
    dialogTitle: function() {
      switch (this.dialogType) {
        case 'edit':
          return `${this.$t('m.edit')}`
        case 'view':
          return `${this.$t('m.show')}`
        default:
          return `${this.$t('m.add')}`
      }
    },
    inputReadonly: function() {
      return this.dialogType === 'view'
    },

  },
  watch: {
    currentApp: function(val) {
      this.listRoles()
    },
  },
  created() {
    this.listRoles()
  },
  mounted() {},
  methods: {
    async listRoles() {
      this.listQuery.appID = this.currentApp
      const res = await listRoles(this.listQuery)
      if (res.ok) {
        this.total = res.data.total
        this.roles = res.data.roles
        if (this.roles) {
          this.roles.forEach(role => {
            role.permIDs = role.permIDs || []
          })
        }
      }
    },

    async validateRoleId(rule, value, callback) {
      if (this.dialogType === 'edit' || this.dialogType === 'view') {
        callback()
        return
      }
      const res = await checkRoleIDExist(this.currentApp, value)
      if (res.ok && res.exist) {
        // callback(new Error(`${$t('m.roleName')} '${value}' ${$t('m.alreadyExist')}`))
      } else {
        callback()
      }
    },

    async validateRoleName(rule, value, callback) {
      const res = await checkRoleNameExist(this.currentApp, value, this.role.id)
      if (res.ok && res.exist) {
        // callback(new Error(`${$t('m.roleName')} '${value}' ${$t('m.alreadyExist')}`))
      } else {
        callback()
      }
    },

    handleFilter() {
      this.listQuery.page = 1
      this.listRoles()
    },

    handleAdd() {
      this.role = Object.assign({}, defaultRole)
      this.role.appID = this.currentApp
      this.dialogType = 'new'
      this.dialogVisible = true
    },
    handleEdit(scope) {
      this.dialogType = 'edit'
      this.dialogVisible = true
      this.checkStrictly = true
      this.role = deepClone(scope.row)
    },
    handleView(scope) {
      this.dialogType = 'view'
      this.dialogVisible = true
      this.checkStrictly = true
      this.role = deepClone(scope.row)
    },
    handleDelete({ $index, row }) {
      this.$confirm(this.$t('m.deleteRoleWarningMsg'), this.$t('m.warningPopTitle'), {
        confirmButtonText: this.$t('m.confirm'),
        cancelButtonText: this.$t('m.cancel'),
        type: 'warning',
      })
        .then(async() => {
          const res = await deleteRole(row.id, row.appID)
          if (res.ok) {
            this.listRoles()
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
          await this.submitRole()
        } else {
          return false
        }
      })
    },

    async submitRole() {
      const isEdit = this.dialogType === 'edit'

      if (isEdit) {
        const res = await updateRole(this.role.id, this.role)
        if (!res.ok) {
          return
        }
        this.listRoles()

        const { name } = this.role
        this.dialogVisible = false
        this.$notify({
          title: this.$t('m.successTitle'),
          dangerouslyUseHTMLString: true,
          message: `
            <div>${this.$t('m.alterRoleMsg')} '${name}' ${this.$t('m.successTitle')}.</div>
          `,
          type: 'success',
        })
      } else {
        const res = await addRole(this.role)
        if (!res.ok) {
          return
        }
        this.listRoles()
        this.role = res.data.role
        const { name } = this.role
        this.dialogVisible = false
        this.$notify({
          title: this.$t('m.success'),
          dangerouslyUseHTMLString: true,
          message: `<div>${this.$t('m.role')} '${name}' ${this.$t('m.added')}.</div>`,
          type: 'success',
        })
      }
    },
    appChange(val) {
      this.listRoles()
    },
  },
}
</script>

<style lang="scss" scoped>

</style>
