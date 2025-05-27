module Api
  module V1
    class PostsController < ApplicationController
      def create
        user = User.find_or_initialize_by(login: post_params[:login])

        if user.new_record?
          unless user.save
            return render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        post = user.posts.build(
          title: post_params[:title],
          body: post_params[:body],
          ip: post_params[:ip] || request.remote_ip.presence
        )

        if post.save
          render json: {
            data: {
              post: post.attributes,
              user: user.attributes
            }
          }, status: :created
        else
          render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def post_params
        params.permit(:login, :title, :body, :ip)
      end
    end
  end
end
