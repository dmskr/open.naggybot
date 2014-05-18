naggyBotControllers = angular.module 'naggyBotControllers', []

naggyBotControllers.controller 'RepoIndexCtrl', ['$scope', '$http', ($scope, $http) ->
  $http.get('https://api.github.com/user/repos?access_token=' + $('#token').val()).success (data) ->
    $scope.repos = data
]

naggyBotControllers.controller 'RepoShowCtrl', ['$scope', '$routeParams', '$http', ($scope, $routeParams, $http) ->
  $http.get("https://api.github.com/repos/#{$routeParams.owner}/#{$routeParams.repo}?access_token=#{$('#token').val()}").success (data) ->
    $scope.repo = data
]


