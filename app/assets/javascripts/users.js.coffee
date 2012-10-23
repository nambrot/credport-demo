# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

# = require lightbox
# = require backbone-rails

class User extends Backbone.Model
  urlRoot: 'http://localhost:5000/api/v1/users'
  parse: (resp, xhr) ->
    resp.user
  verifications: (callback) ->
    if !@verificationsobject?
      @verificationsobject = new VerificationCollection()
      @verificationsobject.user = this
      @verificationsobject.url = @urlRoot + '/' + @get('id') + '/verifications'
      @verificationsobject.on 'reset', (evt) =>
        callback @verificationsobject
      @verificationsobject.fetch()
    else
      callback @verificationsobject
  work: (callback) ->
    if !@workobject?
      @workobject = new WorkHistory(@get('work') || [])
      @workobject.user = this
    callback @workobject
  education: (callback) ->
    if !@educationobject?
      @educationobject = new EducationHistory(@get('education') || [])
      @educationobject.user = this
    callback @educationobject
  reviews: (callback) ->
    if !@reviewsobject?
      @reviewsobject = new Reviews(@get('reviews') || [])
      @reviewsobject.user = this
    callback @reviewsobject
  socialconnections: (callback) ->
    if !@socialconnectionsobject?
      @socialconnectionsobject = new SocialConnections()
      @socialconnectionsobject.user = this
      @socialconnectionsobject.url = @url() + '/socialconnections/'
      @socialconnectionsobject.on 'reset', (evt) =>
        @trigger 'change'
        callback @socialconnectionsobject
      @socialconnectionsobject.fetch()
    else
      callback @socialconnectionsobject
  commoninterests: (callback) ->
    if !@commoninterestsobject?
      @commoninterestsobject = new CommonInterests()
      @commoninterestsobject.user = this
      @commoninterestsobject.url = @url() + '/commoninterests/'
      @commoninterestsobject.on 'reset', (evt) =>
        @trigger 'change'
        callback @commoninterestsobject
      @commoninterestsobject.fetch()
    else
      callback @commoninterestsobject
class Identity extends Backbone.Model

class Path extends Backbone.Model
  nodes: ->
    if !@nodesobject?
      @nodesobject = _.map @get('nodes'), (node) ->
        new Identity(node)
    @nodesobject
  connections: ->
    @get('connections')
      
class SocialConnections extends Backbone.Collection
  model: Path
  parse: (resp, xhr) -> 
    resp.data
    
class CommonInterests extends Backbone.Collection
  model: Path
  parse: (resp, xhr) -> 
    resp.data

class UserButtonView extends Backbone.View
  model: User
  initialize: ->
    @model.on 'change', @render, this
  events:
    "click #openProfile": "openProfile"
  openProfile: ->
    $("<div id='credport-overlay'><header><p>Check out this Credport profile in full size: <a href='#{@model.get('url')}'>#{@model.get('url')}</a></p></header><span class='close'></span><div id='credport-overlay-iframe-container'><svg class='shadow' pointer-events='none'></svg><iframe src='#{@model.get('url')}'></iframe></div></div>").lightbox_me()
    return false
    # TODO: watch out XSS
  template: _.template "
<header>
  <img src='<%= user.image %>' />
  <h3><%= user.name %></h3>
</header>
<% if (user.verifications.identities.length > 0 || user.verifications.real.length > 0) {%>
  <section id='verifications'>   
    <header>
      <h4>Verifications</h4>
    </header>
   <% for (var i = 0; i < user.verifications.identities.length; i++){ %>
      <img class='credport-profile-identity' src='<%= user.verifications.identities[i].image %>'>   
    <% } %>
    <% for (var i = 0; i < user.verifications.real.length; i++){ %>
      <img class='credport-profile-identity' src='<%= user.verifications.real[i].image %>'>   
    <% } %>
    </section>
<% } %>
<% if (socialconnections && socialconnections.models.length > 0) {%>
  <section id='verifications'>   
    <header>
      <h4>Social Connections</h4>
    </header>
   <% for (var i = 0; i < socialconnections.models.length; i++){ %>
      <img class='credport-profile-identity' src='<%= socialconnections.models[i].get('nodes')[1].image %>'>   
    <% } %>
    </section>
<% } %>
<% if (commoninterests && commoninterests.models.length > 0) {%>
  <section id='verifications'>   
    <header>
      <h4>Common Interests</h4>
    </header>
   <% for (var i = 0; i < commoninterests.models.length; i++){ %>
      <img class='credport-profile-identity' src='<%= commoninterests.models[i].get('nodes')[1].image %>'>   
    <% } %>
    </section>
<% } %>
<p><a id='openProfile' href='<%= user.url %>'>Open Profile</a></p> 
  "
  render: ->
    @$el.html @template user: @model.toJSON(), socialconnections: @model.socialconnectionsobject, commoninterests: @model.commoninterestsobject
    this
window.renderButton = (email) ->
  $("#credport-signup").click ->
    newwindow=window.open('http://localhost:5000/signup','name','height=400,width=750,top=100,left=100')
    class Check
      check: ->
        if newwindow.closed
          window.renderButton email
        else
          setTimeout (=>
            @check()), 500
    new Check().check()
    return false
  $.ajax
      type: 'GET'
      url: "http://localhost:5000/api/v1/users/1?email=#{email}&include=verifications"
      async: false
      contentType: "application/json"
      dataType: 'jsonp'
      success: (resp) ->
        if resp.status == 200
          user = new User resp.user
          userview = new UserButtonView({model: user, el: $('#credport-button')[0]})
          userview.render()
          $.ajax
              type: 'GET'
              url: "http://localhost:5000/api/v1/users/1/socialconnections?email=#{email}&include=verifications"
              async: false
              contentType: "application/json"
              dataType: 'jsonp'
              success: (resp) ->
                user.socialconnectionsobject = new SocialConnections resp.data
                user.trigger 'change'
          $.ajax
              type: 'GET'
              url: "http://localhost:5000/api/v1/users/1/commoninterests?email=#{email}&include=verifications"
              async: false
              contentType: "application/json"
              dataType: 'jsonp'
              success: (resp) ->
                user.commoninterestsobject = new CommonInterests resp.data
                user.trigger 'change'
                
        else
          # view = new MissingUserView
          # $('#credport-button').append view.render().el
