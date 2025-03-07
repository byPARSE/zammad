class App.User extends App.Model
  @configure 'User', 'login', 'firstname', 'lastname', 'email', 'web', 'password', 'phone', 'fax', 'mobile', 'street', 'zip', 'city', 'country', 'organization_id', 'department', 'note', 'role_ids', 'group_ids', 'active', 'invite', 'signup', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/users'

#  @hasMany 'roles', 'App.Role'
  @configure_attributes = [
    { name: 'login',            display: __('Login'),         tag: 'input',    type: 'text',     limit: 100, null: false, autocapitalize: false, signup: false, quick: false, no_perform_changes: true },
    { name: 'firstname',        display: __('First name'),    tag: 'input',    type: 'text',     limit: 100, null: true, signup: true, info: true, invite_agent: true, invite_customer: true },
    { name: 'lastname',         display: __('Last name'),     tag: 'input',    type: 'text',     limit: 100, null: true, signup: true, info: true, invite_agent: true, invite_customer: true },
    { name: 'email',            display: __('Email'),         tag: 'input',    type: 'email',    limit: 100, null: true, signup: true, info: true, invite_agent: true, invite_customer: true },
    { name: 'organization_id',  display: __('Organization'),  tag: 'select',   multiple: false, nulloption: true, null: true, relation: 'Organization', signup: false, info: true, invite_customer: true, note: __("Attention! Changing the organization will update the user's most recent tickets to the new organization.") },
    { name: 'group_ids',        display: __('Group permissions'), tag: 'group_permissions', item_class: 'checkbox' },
    { name: 'created_by_id',    display: __('Created by'),    relation: 'User', readonly: 1 },
    { name: 'created_at',       display: __('Created at'),    tag: 'datetime',  readonly: 1 },
    { name: 'updated_by_id',    display: __('Updated by'),    relation: 'User', readonly: 1 },
    { name: 'updated_at',       display: __('Updated at'),    tag: 'datetime',  readonly: 1 },
  ]
  @configure_overview = [
#    'login', 'firstname', 'lastname', 'email', 'updated_at',
    'login', 'firstname', 'lastname', 'organization'
  ]
  @configure_preview = [
    'login', 'firstname', 'lastname', 'organization', 'created_at'
  ]
  @allowedReplaceTagsFunctionMapping = {
    avatar: {
      function_name: 'avatar_image_tag',
      placeholder_display: __('Avatar'),
      placeholder_content: 'avatar(60,60)',
    }
  }

  uiUrl: ->
    "#user/profile/#{@id}"

  icon: ->
    'user'

  initials: ->
    if @firstname && @lastname && @firstname[0] && @lastname[0]
      return @firstname[0] + @lastname[0]

    if @firstname && @firstname[0] && !@lastname
      if @firstname[1]
        return @firstname[0] + @firstname[1]
      return @firstname[0]

    if !@firstname && @lastname && @lastname[0]
      if @lastname[1]
        return @lastname[0] + @lastname[1]
      return @lastname[0]

    if @email
      return @email[0] + @email[1]

    if @phone
      return @phone.slice(-2)

    if @mobile
      return @mobile.slice(-2)

    return '??'

  avatar: (size = 40, placement = '', cssClass = '', unique = false, avatar, type = undefined) ->
    baseSize = 40
    size   = parseInt(size, 10)

    cssClass += ' ' if cssClass
    cssClass += "size-#{ size }"

    if @active is false
      cssClass += ' avatar--inactive'

    if @isOutOfOffice()
      cssClass += ' avatar--vacation'

    if placement
      placement = " data-placement='#{placement}'"

    if !avatar
      if type is 'personal'
        vip = false
        data = " data-id=\"#{@id}\""
      else
        cssClass += ' user-popover'
        data      = " data-id=\"#{@id}\""
    else
      vip = false
      data = " data-avatar-id=\"#{avatar.id}\""

    # set vip flag, ignore if personal avatar is request
    vip = @vip
    if type is 'personal'
      vip = false
    else
      cssClass += ' user-popover'

    # use system avatar for system actions
    if @id is 1
      return App.view('avatar_system')()

    # generate uniq avatar
    if !@image || @image is 'none' || unique
      width  = 300 * size/baseSize
      height = 226 * size/baseSize

      rng = new Math.seedrandom(@id)
      x   = rng() * (width - size)
      y   = rng() * (height - size)

      return App.view('avatar_unique')
        data: data
        cssClass: cssClass
        placement: placement
        vip: vip
        x: x
        y: y
        initials: @initials()

    # generate image based avatar
    return App.view('avatar')
      data: data
      cssClass: cssClass
      placement: placement
      vip: vip
      url: @imageUrl()
      initials: @initials()

  # Used to return a image tag (e.g. for variable replacement).
  avatar_image_tag: (width = 60, height = 60) ->
    image_url = @imageUrl()
    return if !image_url

    '<img src="' + image_url + '" width="' + width + '" height="' + height + '" data-user-avatar="true" />'


  isOutOfOffice: ->
    return false if @out_of_office isnt true
    start_time = @out_of_office_start_at
    return false if !start_time
    end_time = @out_of_office_end_at
    return false if !end_time
    start_time = new Date(Date.parse(start_time))
    end_time = new Date(Date.parse(end_time))
    now = new Date((new Date).toDateString())
    now.setDate(now.getDate() + 1)
    if start_time <= now && end_time >= now
      return true
    false

  maxLoginFailedReached: ->
    return @login_failed > (parseInt(App.Config.get('password_max_login_failed')))

  imageUrl: ->
    return if !@image
    # set image url
    @constructor.apiPath + '/users/image/' + @image

  @_fillUp: (data) ->

    # set social media links
    if data['accounts']
      for account of data['accounts']
        if account == 'twitter'
          data['accounts'][account]['link'] = 'https://twitter.com/' + data['accounts'][account]['username']
        if account == 'facebook'
          data['accounts'][account]['link'] = 'https://www.facebook.com/profile.php?id=' + data['accounts'][account]['uid']

    if data.organization_id
      data.organization = App.Organization.findNative(data.organization_id)

    if data['role_ids']
      data['roles'] = []
      for role_id in data['role_ids']
        if App.Role.exists(role_id)
          role = App.Role.findNative(role_id)
          data['roles'].push role

    if data['group_ids']
      data['groups'] = []
      for group_id in data['group_ids']
        if App.Group.exists(group_id)
          group = App.Group.findNative(group_id)
          data['groups'].push group

    data

  searchResultAttributes: ->
    classList = ['user', 'user-popover']
    icon = 'user'

    if @active is false
      classList.push 'is-inactive'
      icon = 'inactive-' + icon

    display: "#{@displayName()}"
    id:      @id
    class:   classList.join(' ')
    url:     @uiUrl()
    icon:    icon

  activityMessage: (item) ->
    return if !item
    return if !item.created_by

    if item.type is 'create'
      return App.i18n.translateContent('%s created user |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'update'
      return App.i18n.translateContent('%s updated user |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'session started'
      return App.i18n.translateContent('%s started a new session', item.created_by.displayName())
    else if item.type is 'switch to'
      to = item.title
      if item.objectNative
        to = item.objectNative.displayName()
      return App.i18n.translateContent('%s switched to |%s|!', item.created_by.displayName(), to)
    else if item.type is 'ended switch to'
      to = item.title
      if item.objectNative
        to = item.objectNative.displayName()
      return App.i18n.translateContent('%s ended switch to |%s|!', item.created_by.displayName(), to)
    return "Unknow action for (#{@objectDisplayName()}/#{item.type}), extend activityMessage() of model."

  ###

    user = App.User.find(3)
    result = user.permission('ticket.agent') # access to certain permission key
    result = user.permission(['ticket.agent', 'ticket.customer']) # access to one of permission keys

    result = user.permission('user_preferences.calendar+ticket.agent') # access must have two permission keys

    result = user.permission('admin.*') # access if one sub key access exists

  returns

    true|false

  ###

  permission: (key) ->
    keys = key
    if !_.isArray(key)
      keys = [key]

    # if any permission exists
    return true if _.contains(keys, '*')

    # verify direct permissions
    for key in keys
      permission = App.Permission.findByAttribute('name', key)
      return false if permission && permission.active is false

    # get all permissions of user
    permissions = {}
    for role_id in @role_ids
      role = App.Role.findNative(role_id)
      if role.active is true
        for permission_id in role.permission_ids
          permission = App.Permission.findNative(permission_id)
          if !permission
            throw "No such permission for id #{permission_id}"
          if permission.active is true
            permissions[permission.name] = true

    for localKey in keys
      requiredPermissions = localKey.split('+')
      access = false
      for requiredPermission in requiredPermissions
        localAccess = false
        partString = ''
        parts = requiredPermission.split('.')

        # verify name.* permissions
        if parts[parts.length - 1] is '*'
          for permission_key, permission_value of permissions
            if permission_value is true
              length = requiredPermission.length - 1
              if permission_key.substr(0, length) is requiredPermission.substr(0, length)
                localAccess = true

        # verify name.explicit permissions
        if !localAccess
          for part in parts
            if partString isnt ''
              partString += '.'
            partString += part
            if permissions[partString]
              localAccess = true

        if localAccess
          access = true
        else
          access = false
          break
      return access if access
    false

  ###

    Returns a list of all groups for which the user is permitted to perform the given permission key

    user = App.User.find(3)
    result = user.allGroupIds('change') # access to a given permission key

  returns

    ["1", "2"]

  ###
  allGroupIds: (permission = 'full') ->
    group_ids = []
    user_group_ids = @group_ids
    if user_group_ids
      for local_group_id, local_permission of user_group_ids
        if _.include(local_permission, permission) || _.include(local_permission, 'full')
          group_ids.push local_group_id

    user_role_ids = @role_ids
    if user_role_ids
      for role_id in user_role_ids
        if App.Role.exists(role_id)
          role = App.Role.findNative(role_id)
          if role.group_ids
            for local_group_id, local_permission of role.group_ids
              if _.include(local_permission, permission) || _.include(local_permission, 'full')
                group_ids.push local_group_id
    _.uniq(group_ids)

  @outOfOfficeTextPlaceholder: ->
    today = new Date()
    outOfOfficeText = App.i18n.translatePlain('Christmas holiday')
    if today.getMonth() < 3
      outOfOfficeText = App.i18n.translatePlain('Easter holiday')
    else if today.getMonth() < 9
      outOfOfficeText = App.i18n.translatePlain('Summer holiday')
    outOfOfficeText

  outOfOfficeText: ->
    return @preferences.out_of_office_text if !_.isEmpty(@preferences.out_of_office_text)
    App.User.outOfOfficeTextPlaceholder()

  ###

    Checks if requester has given access level on requested.
    Possible access levels are: read, update and delete
    See backend policy UserPolicy

    requester = App.User.find(1)
    requested = App.User.find(3)
    result    = requested.isAccessibleBy(requester, 'read')

  returns

    true|false

  ###

  isAccessibleBy: (requester, access) ->
    return true if requester.permission('admin')

    capitalized  = access.charAt(0).toUpperCase() + access.slice(1)
    accessMethod = 'is' + capitalized + 'ableBy'
    @[accessMethod](requester)

  isReadableBy: (requester) ->
    return true if @ownAccount(requester)
    return true if requester.permission('admin.*')
    return true if requester.permission('ticket.agent')
    # check same organization for customers
    return false if !requester.permission('ticket.customer')
    @sameOrganization?(requester)

  isChangeableBy: (requester) ->
    # full access for admins
    return true if requester.permission('admin.user')
    # forbid non-agents to change users
    return false if !requester.permission('ticket.agent')
    # allow agents to change customers only
    return false if @permission(['admin.user', 'ticket.agent'])
    @permission('ticket.customer')

  isDeleteableBy: (requester) ->
    requester.permission('admin.user')

  ownAccount: (requester) ->
    @id is requester.id

  sameOrganization: (requester) ->
    return false if @organization_id is null
    return false if requester.organization_id is null
    @isInOrganization(requester.organization_id)

  lifetimeCustomerTicketsCount: ->
    (@preferences.tickets_closed || 0) + (@preferences.tickets_open || 0)

  isInOrganization: (organization_id) ->
    _.contains(@allOrganizationIds(), parseInt(organization_id, 10))

  allOrganizationIds: ->
    result = []
    if @organization_id
      result.push(@organization_id)
    if _.isArray(@organization_ids)
      result = result.concat(@organization_ids)
    _.uniq(result)

  secondaryOrganizations: (offset, limit, callback) ->
    organization_ids = []
    missing_organization_ids = []
    if _.isArray(@organization_ids)
      organization_ids         = @organization_ids.slice(offset, limit)
      missing_organization_ids = _.filter(organization_ids, (id) -> !App.Organization.findNative(id))

    organizationResult = ->
      organizations = []
      for organization_id in organization_ids
        organization = App.Organization.fullLocal(organization_id)
        continue if !organization
        organizations.push(organization)
      return organizations

    return callback(organizationResult()) if missing_organization_ids.length < 1

    App.Ajax.request(
      type: 'POST'
      url: "#{@constructor.apiPath}/organizations/search"
      data: JSON.stringify(
        query: '*'
        ids: missing_organization_ids
        limit: limit
        full:  true
      )
      processData: true,
      success: (data, status, xhr) ->
        App.Collection.loadAssets(data.assets)
        callback(organizationResult())
      error: (data, status) ->
        callback([])
    )

  # Do NOT modify the return value of this method!
  # It is a direct reference to a value in the App.User.irecords object.
  @current: App.Session.get

  displayName: ->
    if !_.isEmpty(@firstname)
      name = @firstname
    if !_.isEmpty(@lastname)
      if _.isEmpty(name)
        name = ''
      else
        name = name + ' '
      name = name + @lastname
    return name if !_.isEmpty(name)
    if @email
      return @email
    if @phone
      return @phone
    if @mobile
      return @mobile
    if @login
      return @login
    return '-'

  displayNameLong: ->
    if !_.isEmpty(@firstname)
      name = @firstname
    if !_.isEmpty(@lastname)
      if _.isEmpty(name)
        name = ''
      else
        name = name + ' '
      name = name + @lastname
    if !_.isEmpty(name)
      if !_.isEmpty(@organization)
        if typeof @organization is 'object'
          name = "#{name} (#{@organization.name})"
        else
          name = "#{name} (#{@organization})"
      else if !_.isEmpty(@department)
        name = "#{name} (#{@department})"
    return name if !_.isEmpty(name)
    if @email
      return @email
    if @phone
      return @phone
    if @mobile
      return @mobile
    if @login
      return @login
    return '-'
