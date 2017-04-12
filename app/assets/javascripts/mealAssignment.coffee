iosDragDropShim = { enableEnterLeave: true }

Vue.component 'weekday-meal',
  props: ["weekday", "mealAssigned", "removeAssignment", "verticalLayout", "mealIsBeingDragged"]
  template: """
    <div
      v-bind:class="{'flex': !verticalLayout}"
      class="weekday bg-white p1 relative rounded flex-auto">
      <div v-bind:class="{ 'flex flex-auto': !verticalLayout }" >
        <div v-if="isToday" class="box2 p1 c-green" :class="{ 'top-left': !verticalLayout, 'top-right': verticalLayout }">
          <svg fill="currentColor" viewBox="0 0 20 20"><polygon points="10 15 4.122 18.09 5.245 11.545 .489 6.91 7.061 5.955 10 0 12.939 5.955 19.511 6.91 14.755 11.545 15.878 18.09"/></svg>
        </div>

        <div v-bind:class="{'flex-25 pr2 flex-center flex-column': !verticalLayout}" >
          <h4 class="center mt1 mb0">{{ weekday.table.title }}</h4>
          <h6 class="center mt0 mb2">{{ weekday.table.date }}</h6>
        </div>
        <div v-if="meal" class="bg-grey flex-25 mr1 p1 rounded relative">
          <span class="top-right box2 flex-center cursor" @click="removeAssignment(meal)">&times</span>
          <h3 class="center m0">{{ meal.name }}</h3>
          <h6>Notes</h6>
          <h6>Ingredients</h6>
        </div>
        <div
          v-on:dragover="draggingOver"
          v-on:dragenter="draggingEnter"
          v-on:dragleave="draggingLeaving"
          v-on:drop="onDrop"
          v-bind:class="{'border-dashed flex-auto flex-center p1 rounded': mealIsBeingDragged }">
          <div v-show='isDraggingOver' class="box2 c-green" style="pointer-events: none;">
            <svg fill="currentColor" viewBox="0 0 20 20"><path d="M11 9V5H9v4H5v2h4v4h2v-4h4V9h-4zm-1 11a10 10 0 1 1 0-20 10 10 0 0 1 0 20z"/></svg>
          </div>
          <span v-show="isLoading">Loading...</span>
        </div>
      </div>
    </div>
  """
  data: ->
    isDraggingOver: false
    isLoading: false
  computed:
    meal: -> @weekday.table.meal
    isToday: ->
      todaysDate = new Date()
      mealDate = new Date(@weekday.table.date)
      "#{todaysDate.getUTCDate()} - #{todaysDate.getUTCMonth()}" is
        "#{mealDate.getUTCDate()} - #{mealDate.getUTCMonth()}"
  methods:
    draggingOver: (evt) ->
      evt.preventDefault()
      unless @isDraggingOver
        @isDraggingOver = true
    draggingEnter: (evt) ->
      evt.preventDefault()
      @isDraggingOver = true
    draggingLeaving: (evt) ->
      @isDraggingOver = false
    onDrop: (evt) ->
      evt.preventDefault()
      @isLoading = true
      Axios.post "/meal-assignments", {
        weekdate: @weekday.table.date
        meal_id: evt.dataTransfer.getData("text")
      }
      .then (resp) =>
        @isDraggingOver = false
        @isLoading = false
        #console.info(resp)
        @mealAssigned(resp.data.mealbook)

Vue.component 'weekday-meals',
  props: ["weekdays", "mealAssigned", "removeAssignment", "verticalLayout", "mealIsBeingDragged"]

  template: """
    <div v-bind:class="{'flex-column': !verticalLayout}" class="weekday-meals px1 pb2 flex flex-1">
      <div v-for="(weekday, index) in weekdays" v-bind:class="{'pb2 ht8': !verticalLayout}" class="weekday px1 flex">
        <weekday-meal
          :removeAssignment="removeAssignment"
          :mealAssigned="mealAssigned"
          :weekday="weekday"
          :mealIsBeingDragged='mealIsBeingDragged'
          :verticalLayout="verticalLayout">
        </weekday-meal>
      </div>
    </div>
  """

Vue.component 'meal-list-meal',
  props:
    meal: Object
    startMealDrag: Function,
    stopMealDrag: Function,
  template: """
    <div
      draggable="true"
      v-on:dragstart="draggingStarted"
      v-on:dragend="draggingStopped"
      class="meal-list-meal relative">

      <span class="flex-1">{{ meal.name }}</span>
      <a v-bind:href="mealUrl" class="box2 c-gray">
        <svg fill="currentColor" viewBox="0 0 20 20"><path d="M10 12a2 2 0 1 1 0-4 2 2 0 0 1 0 4zm0-6a2 2 0 1 1 0-4 2 2 0 0 1 0 4zm0 12a2 2 0 1 1 0-4 2 2 0 0 1 0 4z"/></svg>
      </a>
    </div>
  """
  data: ->
    draggingHasStarted: false
  computed:
    mealUrl: ->
      "/meals/#{@meal.id}"
  methods:
    draggingStarted: (evt) ->
      @draggingHasStarted = true
      @startMealDrag()
      evt.dataTransfer.setData("text", @meal.id)
    draggingStopped: (evt) ->
      @stopMealDrag()

document.addEventListener "turbolinks:load", ->
  if document.getElementById("mealbook")
    _mealbookPlanner = new Vue(
      el: '#mealbook'
      template: """
        <main class="main flex flex-auto">
          <div class='flex flex-column flex-auto'>
            <section class="flex justify-between ht4" data-turbolinks='false'>
              <div class='flex-15'></div>
              <div class='flex-center'>
                <a @click.prevent="renderPrevWeek" href="#prev" style="width: 20px; height: 20px;">
                  <svg fill="currentColor" viewBox="0 0 20 20"><path d="M10 20a10 10 0 1 1 0-20 10 10 0 0 1 0 20zm8-10a8 8 0 1 0-16 0 8 8 0 0 0 16 0zM7.46 9.3L11 5.75l1.41 1.41L9.6 10l2.82 2.83L11 14.24 6.76 10l.7-.7z"/></svg>
                </a>
                <h2 class='m0 px1'>{{ mealbook.current_date_short }}</h2>
                <a @click.prevent="renderNextWeek" href="#next" style="width: 20px; height: 20px;">
                  <svg fill="currentColor" viewBox="0 0 20 20"><path d="M10 0a10 10 0 1 1 0 20 10 10 0 0 1 0-20zM2 10a8 8 0 1 0 16 0 8 8 0 0 0-16 0zm10.54.7L9 14.25l-1.41-1.41L10.4 10 7.6 7.17 9 5.76 13.24 10l-.7.7z"/></svg>
                </a>
              </div>
              <div class='flex-center flex-15'>
                <div class='flex bg-white rounded'>
                  <div @click="verticalLayout = false" v-bind:class="{'c-green': !  verticalLayout}" class='box2 flex-center cursor'>
                    <svg class='icon' fill='currentColor' viewBox="0 0 20 20"><path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z"/></svg>
                  </div>
                  <div @click="verticalLayout = true" v-bind:class="{'c-green': verticalLayout}" class='box2 flex-center cursor rotate-90'>
                    <svg class='icon' fill='currentColor' viewBox="0 0 20 20"><path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z"/></svg>
                  </div>
                </div>
              </div>
            </section>
            <section class='main-weekdays flex flex-auto items-strech'>
              <weekday-meals
                :weekdays="weekdays"
                :removeAssignment="destroyAssignment"
                :mealAssigned="updateWeek"
                :mealIsBeingDragged='mealIsBeingDragged'
                :verticalLayout="verticalLayout">
              </weekday-meals>
            </section>
          </div>
          <section class='main-meals scroll-y' v-bind:class="{ 'main-meals__hidden': !showMealDrawer }">
            <div @click="showMealDrawer = !showMealDrawer" class="main-meals__toggle">&times</div>
            <div class='meal-list' id='mealbookMeals'>
              <h4 class="mt0 mb1">Meals</h4>
              <meal-list-meal
                :mealIsBeingDragged='mealIsBeingDragged'
                :stopMealDrag='stopMealDrag'
                :startMealDrag='startMealDrag'
                :meal='meal'
                :key="meal.id"
                v-for='(meal, index) in meals'>
              </meal-list-meal>
            </div>
          </section>
        </main>
      """
      data:
        mealbook: window._currentMealbook
        showMealDrawer: true
        verticalLayout: false
        mealIsBeingDragged: false
      computed:
        weekdays: () ->
          @mealbook.weekdays
        meals: ->
          @mealbook.meals
      methods:
        startMealDrag: () ->
          @mealIsBeingDragged = true
        stopMealDrag: () ->
          @mealIsBeingDragged = false
        updateWeek: (newMealbook) ->
          @mealbook = newMealbook
        renderPrevWeek: () ->
          @renderWeek(@mealbook.prev_week)
        renderNextWeek: () ->
          @renderWeek(@mealbook.next_week)
        destroyAssignment: ({ assignment_id }) ->
          Axios.delete "/meal-assignments/#{assignment_id}"
            .then (response) => @mealbook = response.data.mealbook
        renderWeek: (dateParam) ->
          Axios.get "/mealbooks/#{@mealbook.id}", params: { weekdate: dateParam }
            .then (response) =>
              @mealbook = response.data.mealbook
    )
