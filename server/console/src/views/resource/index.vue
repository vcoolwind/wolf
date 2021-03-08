<template>
  <div class="app-container">

    <div class="filter-container">
      <div class="filter-item">{{ $t('m.app') }}:</div>
      <current-app class="current-app filter-item" />
      <el-input
        v-model="listQuery.key"
        :placeholder="$t('m.resourceNameOrPermission')"
        style="width: 200px;"
        class="filter-item"
        maxlength="32"
        clearable
        @keyup.enter.native="handleFilter"
      />
      <el-button class="filter-item" type="primary" icon="el-icon-search" @click="handleFilter">
        {{ $t('m.search') }}
      </el-button>
      <el-button class="filter-item" type="primary" @click="handleAdd">{{ $t('m.newResource') }}</el-button>
    </div>

    <el-table :data="resources" style="margin-top:30px; " border>
      <el-table-column align="center" :label="$t('m.app')" min-width="20" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.appID }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.matchType')" min-width="20" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.matchTypeName }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.name')" min-width="60" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.name }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.action')" min-width="20" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.action }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.permission')" min-width="20" show-overflow-tooltip>
        <template slot-scope="scope">
          {{ scope.row.permission_name }}
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('m.createTime')" min-width="20" show-overflow-tooltip prop="createTime" :formatter="unixtimeFormat" />
      <el-table-column align="center" :label="$t('m.operations')" min-width="20" show-overflow-tooltip>
        <template slot-scope="scope">
          <el-button type="primary" size="small" @click="handleEdit(scope)">{{ $t('m.edit') }}</el-button>
          <el-button type="danger" size="small" @click="handleDelete(scope)">{{ $t('m.delete') }}</el-button>
        </template>
      </el-table-column>
    </el-table>
    <div class="pagination pagination-center">
      <pagination v-show="total>0" :total="total" :page.sync="listQuery.page" :limit.sync="listQuery.limit" @pagination="listResources" />
    </div>

    <el-dialog :visible.sync="dialogVisible" :title="$t(dialogTitle)" custom-class="rbac-edit-dialog">
      <el-form ref="resource" :model="resource" :rules="rules" label-width="120px" label-position="left">
        <el-form-item :label="$t('m.app')" prop="appID">
          <el-select v-model="resource.appID" :placeholder="$t('m.changeApp')" size="small" style="display: block" />
        </el-form-item>
        <el-form-item :label="$t('m.matchType')" prop="matchType">
          <el-select v-model="resource.matchType" size="small" style="display: block">
            <el-option
              v-for="matchType in matchTypes"
              :key="matchType.type"
              :label="$t(matchType.lang)"
              :value="matchType.type"
            />
          </el-select>
        </el-form-item>
        <el-form-item :label="$t('m.action')" prop="action">
          <el-select v-model="resource.action" :placeholder="$t('m.httpMethod')" size="small" style="display: block">
            <el-option v-for="action in actions" :key="action" :label="action" :value="action" />
          </el-select>
        </el-form-item>
        <el-form-item :label="$t('m.name')" prop="name">
          <el-input
            v-model="resource.name"
            :placeholder="$t('m.resourceName')"
          />
        </el-form-item>
        <el-form-item :label="$t('m.permission')" prop="permID">
          <permission-select :value.sync="resource.permID" />
        </el-form-item>
      </el-form>
      <div style="text-align:right;">
        <el-button type="danger" @click="dialogVisible=false">{{ $t('m.cancel') }}</el-button>
        <el-button v-if="dialogType!=='view'" type="primary" @click="validateAndSubmit('resource');">{{ $t('m.confirm') }}</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
// import path from 'path'
import CurrentApp from '@/components/CurrentApp'
import PermissionSelect from '@/components/PermissionSelect'
var _ = require('lodash')
import { deepClone } from '@/utils'
import { listResources, addResource, deleteResource, updateResource, checkResourceExist } from '@/api/resource'
import { listPermissions } from '@/api/permission'
import Pagination from '@/components/Pagination' // secondary package based on el-pagination

const defaultResource = {
  appID: '',
  matchType: 'equal',
  name: '',
  action: 'ALL',
  permID: 'DENY_ALL',
}

export default {
  name: 'Resource',
  components: { CurrentApp, Pagination, PermissionSelect },
  props: {},
  data() {
    return {
      resource: Object.assign({}, defaultResource),
      routes: [],
      resources: [],
      total: 0,
      listQuery: {
        page: 1,
        limit: 10,
        key: undefined,
        appID: null,
        sort: '-createTime',
      },
      permissions: [],
      dialogVisible: false,
      dialogType: 'new',
      checkStrictly: false,
      defaultProps: {
        children: 'children',
        label: 'title',
      },
      matchTypes: [
        { type: 'equal', name: 'Equals Match', lang: 'm.equalsMatch' },
        { type: 'prefix', name: 'Prefix Match', lang: 'm.prefixMatch' },
        { type: 'suffix', name: 'Suffix Match', lang: 'm.suffixMatch' },
      ],
      actions: ['ALL', 'GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', 'PATCH'],
      rules: {
        name: [
          { required: true, message: this.$i18n.locale === 'en-US' ? 'Please input resource name' : '请输入资源名', trigger: ['blur', 'change'] },
          { min: 1, max: 512, message: 'length must be between 1 and 512 characters', trigger: ['blur', 'change'] },
          { validator: this.validateResource, trigger: ['blur', 'change'] },
        ],
        matchType: [
          { validator: this.validateResource, trigger: ['blur', 'change'] },
        ],
        action: [
          { validator: this.validateResource, trigger: ['blur', 'change'] },
        ],
        permID: [
          { required: true, message: this.$i18n.locale === 'en-US' ? 'Please select a permission for resource' : '请选择资源对应的权限', trigger: ['blur', 'change'] },
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
          return 'm.editResource'
        default:
          return 'm.newResource'
      }
    },

  },
  watch: {
    currentApp: function(val) {
      this.listResources()
    },
  },
  created() {
    this.listResources()
  },
  mounted() {},
  methods: {
    getMatchName(matchType) {
      const matchTypeInfo = _.find(this.matchTypes, { type: matchType })
      if (matchTypeInfo) {
        return matchTypeInfo.name
      }
      return matchType
    },
    getPermissionName(permID) {
      const permission = _.find(this.permissions, { id: permID })
      if (permission) {
        return permission.name || permID
      }
      return permID
    },
    async listResources() {
      this.listQuery.appID = this.currentApp
      const res = await listResources(this.listQuery)
      if (res.ok) {
        this.total = res.data.total
        const resources = res.data.resources
        if (resources) {
          const res = await listPermissions({ appID: this.currentApp, limit: 256 })
          if (res.ok) {
            this.permissions = res.data.permissions
          }
          resources.forEach((resource) => {
            const matchTypeName = this.getMatchName(resource.matchType)
            resource.matchTypeName = matchTypeName
            const permissionName = this.getPermissionName(resource.permID)
            resource.permission_name = permissionName
          })
          this.resources = resources
        }
      }
    },

    async validateResource(rule, value, callback) {
      const { matchType, name, action } = this.resource
      const res = await checkResourceExist(this.resource)
      if (res.ok && res.exist) {
        callback(new Error(`${this.$t('m.resource')} '${matchType}:${action}:${name}' ${this.$t('m.alreadyExists')}`))
      } else {
        callback()
      }
    },

    handleFilter() {
      this.listQuery.page = 1
      this.listResources()
    },

    handleAdd() {
      this.resource = Object.assign({}, defaultResource)
      this.resource.appID = this.currentApp
      this.dialogType = 'new'
      this.dialogVisible = true
    },
    handleEdit(scope) {
      this.dialogType = 'edit'
      this.dialogVisible = true
      this.checkStrictly = true
      this.resource = deepClone(scope.row)
    },

    handleDelete({ $index, row }) {
      this.$confirm(this.$t('m.ConfirmRemoveResource'), this.$t('m.warning'), {
        confirmButtonText: this.$t('m.confirm'),
        cancelButtonText: this.$t('m.cancel'),
        type: 'warning',
      })
        .then(async() => {
          const res = await deleteResource(row.id)
          if (res.ok) {
            this.listResources()
            this.$message({
              type: 'success',
              message: this.$t('m.deleteSucced'),
            })
          }
        })
        .catch(err => { console.error(err) })
    },

    async validateAndSubmit(formName) {
      this.$refs[formName].validate(async(valid) => {
        if (valid) {
          await this.submitResource()
        } else {
          return false
        }
      })
    },

    async submitResource() {
      const isEdit = this.dialogType === 'edit'

      if (isEdit) {
        const res = await updateResource(this.resource.id, this.resource)
        if (!res.ok) {
          return
        }
        this.listResources()

        const { name } = this.resource
        this.dialogVisible = false
        this.$notify({
          title: this.$t('m.success'),
          dangerouslyUseHTMLString: true,
          message: `
            <div>${this.$t('m.alter')} ${this.$t('m.resource')} '${name}' ${this.$t('m.success')}</div>
          `,
          type: 'success',
        })
      } else {
        const res = await addResource(this.resource)
        if (!res.ok) {
          return
        }
        this.listResources()
        this.resource = res.data.resource
        const { name } = this.resource
        this.dialogVisible = false
        this.$notify({
          title: this.$t('m.success'),
          dangerouslyUseHTMLString: true,
          message: `<div>${this.$t('m.resource')} '${name}' ${this.$t('m.added')}</div>`,
          type: 'success',
        })
      }
    },
    appChange(val) {
      this.listResources()
    },
  },
}
</script>

<style lang="scss" scoped>

</style>

