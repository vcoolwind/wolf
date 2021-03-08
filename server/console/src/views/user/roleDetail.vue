<template>
  <div>
    <el-dropdown @command="handlePermissionDetail">
      <el-button type="primary">
        {{ $t('m.detail') }}<i class="el-icon-arrow-down el-icon--right" />
      </el-button>
      <el-dropdown-menu v-if="appIds && appIds.length > 0" slot="dropdown">
        <el-dropdown-item v-for="appID in appIds" :key="appID" :command="appID">{{ appID }}</el-dropdown-item>
      </el-dropdown-menu>
      <el-dropdown-menu v-else slot="dropdown">
        <el-dropdown-item key="no_app" command="">No Application</el-dropdown-item>
      </el-dropdown-menu>
    </el-dropdown>
    <el-dialog :visible.sync="detailDialogVisible" :title="$t('m.detail')" custom-class="rbac-edit-dialog">
      <el-form ref="user" :model="user" label-width="120px" label-position="left">
        <el-form-item :label="$t('m.userName')" prop="username">
          <el-input v-model="user.username" readonly />
        </el-form-item>
        <el-form-item :label="$t('m.nickName')" prop="nickname">
          <el-input v-model="user.nickname" readonly />
        </el-form-item>
        <el-form-item :label="$t('m.appId')" prop="appIDs">
          <el-input v-model="currentApp" readonly />
        </el-form-item>
        <el-form-item :label="$t('m.userPermissions')" prop="permIDs">
          <permission-select :value.sync="userRole.permIDs" :application="currentApp" multiple />
        </el-form-item>
        <el-form-item :label="$t('m.role')" prop="roleIDs">
          <role-select :value.sync="userRole.roleIDs" :application="currentApp" />
        </el-form-item>
      </el-form>
      <div style="text-align:right;">
        <el-button type="danger" @click="detailDialogVisible=false">{{ $t('m.cancel') }}</el-button>
        <el-button type="primary" @click="submit('user')">{{ $t('m.confirm') }}</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getUserRole, setUserRole } from '@/api/user-role'
import PermissionSelect from '@/components/PermissionSelect'
import RoleSelect from '@/components/RoleSelect'

const defaultUserRole = {
  userID: null,
  appID: '',
  permIDs: [],
  roleIDs: [],
}

export default {
  name: 'PermissionDetail',
  components: { PermissionSelect, RoleSelect },
  props: {
    user: {
      type: Object,
      required: true,
    },
  },
  data: function() {
    return {
      currentApp: null,
      userRole: Object.assign({}, defaultUserRole),
      detailDialogVisible: false,
    }
  },
  computed: {
    appIds: function() {
      const appIds = this.user.appIDs || []
      if (this.$store.getters.userInfo.manager === 'super') {
        return appIds
      } else {
        const loginUserAppIds = new Set(this.$store.getters.appIds)
        const intersection = Array.from(new Set(appIds.filter(v => loginUserAppIds.has(v))))
        return intersection
      }
    },
  },
  created: function() {
    // this.listPermissions()
  },
  methods: {
    async getUserRole() {
      const res = await getUserRole(this.user.id, this.currentApp)
      if (res.ok) {
        this.userRole = Object.assign(Object.assign({}, defaultUserRole), (res.data.userRole || defaultUserRole))
      }
      return res
    },
    async permissionClick() {

    },
    async handlePermissionDetail(command) {
      if (!command) {
        return
      }
      this.currentApp = command
      const res = await this.getUserRole()
      if (res.ok) {
        this.detailDialogVisible = true
      } else {
        //
      }
    },
    async submit(formName) {
      const res = await setUserRole(this.userRole)
      if (res.ok) {
        this.userRole = Object.assign({}, defaultUserRole)
        this.detailDialogVisible = false
        this.$notify({
          title: this.$t('m.success'),
          dangerouslyUseHTMLString: true,
          message: `<div>${this.$t('m.alter')} ${this.user.username} ${this.$t('m.de')} ${this.$t('m.userPermissions')}/${this.$t('m.role')} ${this.$t('m.success')}!</div>`,
          type: 'success',
        })
      } else {de
        return false
      }
    },
  },
}

</script>
