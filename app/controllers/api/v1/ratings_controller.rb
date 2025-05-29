module Api
  module V1
    class RatingsController < ApplicationController
      def create
        post = Post.find_by(id: params[:post_id])
        return render json: { errors: [ "Post not found" ] }, status: :not_found unless post

        user = User.find_by(id: params[:user_id])
        return render json: { errors: [ "User not found" ] }, status: :not_found unless user

        value = params[:value].to_i
        unless (1..5).include?(value)
          return render json: { errors: [ "Rating must be between 1 and 5" ] }, status: :unprocessable_entity
        end

        begin
          Rating.create!(post: post, user: user, value: value)
          average = post.ratings.average(:value).to_f.round(2)

          render json: { data: { average_rating: average } }, status: :ok
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
          render json: { errors: [ "User has already rated this post" ] }, status: :unprocessable_entity
        end
      end

      private

      def rating_params
        params.permit(:user_id, :post_id, :value)
      end
    end
  end
end
