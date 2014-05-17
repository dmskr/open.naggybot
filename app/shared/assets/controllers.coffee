naggyBotControllers = angular.module 'naggyBotControllers', []

naggyBotControllers.controller 'RepoIndexCtrl', ['$scope', '$http', ($scope, $http) ->
  $http.get('https://api.github.com/user/repos?access_token=' + $('#token').val()).success (data) ->
    $scope.repos = data
]

naggyBotControllers.controller 'RepoShowCtrl', ['$scope', '$routeParams', ($scope, $routeParams) ->
  $scope.repoId = $routeParams.repoId
]

