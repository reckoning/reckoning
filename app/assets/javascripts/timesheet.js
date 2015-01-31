//= require angular
//= require_tree ./timesheet

var timesheet = angular.module('timesheet', []);

timesheet.controller('WeekController', ['$filter', function($filter) {
  this.date = moment();
  this.dates = [];
  this.setDates = function() {
    var itr = moment(this.date.isoWeekday(1)).twix(this.date.isoWeekday(7)).iterate("days");
    while(itr.hasNext()) {
      var time = itr.next();
      this.dates.push({
        date: time.format('YYYY-MM-DD'),
        day: time.format('ddd'),
        short: time.format('D. MMM'),
        isCurrentDate: time.isSame(moment().toDate(), 'day')
      })
    }
  };
  this.tasks = [];
  this.getTasks = function() {
    var self = this,
        tasks = [{
          name: "Test Task"
        }];
    tasks.forEach(function(task) {
      var timers = [{
        date: '2015-01-30',
        value: 3
      }];
      task.timers = self.initTimers(timers);
    });
    this.tasks = tasks;
  };

  this.initTimers = function(loadedTimers) {
    var timers = [];
    this.dates.forEach(function(date) {
      var timerForData = $filter('filter')(loadedTimers, {date: date.date}, true);
      if (timerForData.length) {
        timers.push(timerForData[0]);
      } else {
        var timer = {
          date: date.date,
          value: null
        };
        timers.push(timer);
      }
    });
    return timers;
  };
  this.sumForTask = function(task) {
    var sum = 0;
    task.timers.forEach(function(timer) {
      if (timer.value) {
        sum += parseInt(timer.value, 10);
      }
    });
    return sum;
  };
  this.sumForDate = function(date) {
    var sum = 0;
    this.tasks.forEach(function(task) {
      task.timers.forEach(function(timer) {
        if (timer.date == date.date && timer.value) {
          sum += parseInt(timer.value, 10);
        }
      });
    });
    return sum;
  };
  this.sumForWeek = function() {
    var sum = 0;
    this.tasks.forEach(function(task) {
      task.timers.forEach(function(timer) {
        if (timer.value) {
          sum += parseInt(timer.value, 10);
        }
      });
    });
    return sum;
  };
  this.removeTask = function(task) {
    var index = this.tasks.indexOf(task);
    this.tasks.splice(index, 1);
  };
  this.addTask = function(taskName) {
    var task = {
      name: taskName
    }
    task.timers = this.initTimers([]);
    this.tasks.push(task);
  };
}]);

timesheet.filter('time', function() {
  return function(input) {
    var hours = Math.floor(input);
    var minutes = Math.round((input % 1) * 60);

    if (hours !== 0 || minutes !== 0) {

      if (minutes < 10) {
        padded = '0' + minutes.toString();
      } else {
        padded = minutes.toString();
      }
      return hours + ':' + padded;
    } else {
      return '0:00';
    }
  };
});
