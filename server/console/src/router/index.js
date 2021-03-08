import Vue from 'vue'
import Router from 'vue-router'

Vue.use(Router)

/* Layout */
import Layout from '@/layout'

/* Router Modules */
// import componentsRouter from './modules/components'
// import chartsRouter from './modules/charts'
// import tableRouter from './modules/table'
// import nestedRouter from './modules/nested'

/**
 * Note: sub-menu only appear when route children.length >= 1
 *
 * hidden: true                   if set true, item will not show in the sidebar(default is false)
 * alwaysShow: true               if set true, will always show the root menu
 *                                if not set alwaysShow, when item has more than one children route,
 *                                it will becomes nested mode, otherwise not show the root menu
 * redirect: noRedirect           if set noRedirect will no redirect in the breadcrumb
 * name:'router-name'             the name is used by <keep-alive> (must set!!!)
 * meta : {
    roles: ['admin','editor']    control the page roles (you can set multiple roles)
    title: 'title'               the name show in sidebar and breadcrumb (recommend set)
    icon: 'svg-name'             the icon show in the sidebar
    noCache: true                if set true, the page will no be cached(default is false)
    affix: true                  if set true, the tag will affix in the tags-view
    breadcrumb: false            if set false, the item will hidden in breadcrumb(default is true)
    activeMenu: '/example/list'  if set path, the sidebar will highlight the path you set
  }
 */

/**
 * constantRoutes
 * a base page that does not have permission requirements
 * all roles can be accessed
 */
export const constantRoutes = [
  {
    path: '/redirect',
    component: Layout,
    hidden: true,
    children: [
      {
        path: '/redirect/:path*',
        component: () => import('@/views/redirect/index'),
      },
    ],
  },
  {
    path: '/login',
    component: () => import('@/views/login/index'),
    hidden: true,
  },
  {
    path: '/auth-redirect',
    component: () => import('@/views/login/auth-redirect'),
    hidden: true,
  },
  {
    path: '/404',
    component: () => import('@/views/error-page/404'),
    hidden: true,
  },
  {
    path: '/401',
    component: () => import('@/views/error-page/401'),
    hidden: true,
  },
  {
    path: '/',
    component: Layout,
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        component: () => import('@/views/dashboard/index'),
        name: 'Dashboard',
        meta: { title: 'm.dashboard', icon: 'dashboard', affix: true },
      },
    ],
  },
  {
    path: '/profile',
    component: Layout,
    redirect: '/profile/index',
    hidden: true,
    children: [
      {
        path: 'index',
        component: () => import('@/views/profile/index'),
        name: 'Profile',
        meta: { title: 'Profile', icon: 'user', noCache: true },
      },
    ],
  },
]

/**
 * asyncRoutes
 * the routes that need to be dynamically loaded based on user roles
 */
export const asyncRoutes = [
  {
    path: '/application',
    component: Layout,
    children: [
      {
        path: 'list',
        component: () => import('@/views/application/index'),
        name: 'ApplicationList',
        meta: {
          title: 'm.application',
          icon: 'component',
          // roles: ['admin'], // or you can only set roles in sub nav
        },
      },
    ],
  },
  {
    path: '/user',
    component: Layout,
    children: [
      {
        path: 'list',
        component: () => import('@/views/user/index'),
        name: 'UserList',
        meta: {
          title: 'm.user',
          icon: 'user',
          // roles: ['admin'], // or you can only set roles in sub nav
        },
      },
    ],
  },
  {
    path: '/role',
    component: Layout,
    children: [
      {
        path: 'list',
        component: () => import('@/views/role/index'),
        name: 'RoleList',
        meta: {
          title: 'm.role',
          icon: 'role',
        },
      },
    ],
  },

  {
    path: '/permission',
    component: Layout,
    redirect: '/permission/index',
    alwaysShow: true, // will always show the root menu
    name: 'Permission',
    meta: {
      title: 'm.permission',
      icon: 'permission',
      collapse: true,
    },
    children: [
      {
        path: 'category',
        component: () => import('@/views/category/index'),
        name: 'Category',
        meta: {
          title: 'm.category',
        },
      },
      {
        path: 'list',
        component: () => import('@/views/permission/index'),
        name: 'PermissionList',
        meta: {
          title: 'm.permission',
        },
      },
    ],
  },
  {
    path: '/resource',
    component: Layout,
    children: [
      {
        path: 'list',
        component: () => import('@/views/resource/index'),
        name: 'ResourceList',
        meta: {
          title: 'm.resource',
          icon: 'resource',
        },
      },
    ],
  },
  {
    path: '/audit',
    component: Layout,
    children: [
      {
        path: 'log',
        component: () => import('@/views/access-log/index'),
        name: 'AuditLog',
        meta: {
          title: 'm.auditLog',
          icon: 'audit',
        },
      },
    ],
  },

  // 404 page must be placed at the end !!!
  { path: '*', redirect: '/404', hidden: true },
]

const routes = constantRoutes.concat(asyncRoutes)

const createRouter = () => new Router({
  // mode: 'history', // require service support
  scrollBehavior: () => ({ y: 0 }),
  routes,
})

const router = createRouter()

// Detail see: https://github.com/vuejs/vue-router/issues/1234#issuecomment-357941465
export function resetRouter() {
  const newRouter = createRouter()
  router.matcher = newRouter.matcher // reset router
}

export default router