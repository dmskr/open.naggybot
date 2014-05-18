naggyBotApp = angular.module('naggyBot', ['ngRoute', 'naggyBotControllers'])

naggyBotApp.config ['$routeProvider', ($routeProvider) ->
  $routeProvider.when '/repos', {
    templateUrl: '/repos/index.html'
    controller: 'RepoIndexCtrl'
  }
  $routeProvider.when '/repos/:owner/:repo', {
    templateUrl: '/repos/show.html'
    controller: 'RepoShowCtrl'
  }
  $routeProvider.otherwise {
    redirectTo: '/repos'
  }
]

