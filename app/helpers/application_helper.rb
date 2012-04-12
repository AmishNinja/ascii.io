module ApplicationHelper
  def twitter_auth_path
    "/auth/twitter"
  end

  def github_auth_path
    "/auth/github"
  end

  def default_avatar_url
    image_path "default_avatar.png"
  end

  def avatar_img(user)
    nickname =  "~#{user.nickname}"
    image_tag user.avatar_url || default_avatar_url,
      :title => nickname, :alt => nickname, :class => "avatar"
  end

  def markdown(&block)
    MKD_RENDERER.render(capture(&block)).html_safe
  end
end
