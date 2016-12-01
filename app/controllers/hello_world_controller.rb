# TODO: Remove after done playing with pusher

class HelloWorldController < ApplicationController
  skip_before_action :authenticate_user!

  def hello_world
    Pusher.trigger('test_channel', 'my_event', {
      message: 'hello world'
    })
  end
end
