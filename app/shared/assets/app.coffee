naggyBotApp = angular.module('naggyBot', [])

naggyBotApp.controller 'Repos', ['$scope', '$http', ($scope, $http) ->

  $http.get('https://api.github.com/user/repos?access_token=' + $('#token').val()).success (data) ->
    $scope.repos = data

  #github.User.repos (err, result) ->
    #$scope.repos = result

  $scope.list =
    [
      { name: 'monkey' }
      { name: 'gibbon' }
      { name: 'arangutang' }
    ]
]

  
