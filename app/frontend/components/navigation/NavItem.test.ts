import mountVM from '~/test/javascript/unit/mount'
import NavItem from '@/components/navigation/NavItem.vue'

describe('NavItem', () => {
  it('renders a link', () => {
    const cmp = mountVM(NavItem, {
      title: 'Home',
      routeName: 'home',
      icon: 'fad fa-home',
    })

    expect(cmp.findAll('a')).toHaveLength(1)
  })
})
