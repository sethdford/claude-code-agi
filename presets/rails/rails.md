# Rails Preset

Ruby on Rails conventions for Claude Code agents building or maintaining Rails applications.

## Project Structure

```
app/
├── models/           # ActiveRecord models with concerns
├── controllers/      # Action controllers with concerns
├── views/           # ERB templates, layouts, partials
├── helpers/         # View helpers
├── mailers/         # ActionMailer classes
├── jobs/            # Active Job background jobs
├── channels/        # ActionCable WebSocket channels
├── services/        # Business logic services (optional)
├── validators/      # Custom validators
└── concerns/        # Shared modules (models/, controllers/)

config/
├── initializers/    # Third-party gem config, Rails hooks
├── locales/         # i18n translations
└── routes.rb        # Route definitions

db/
├── migrate/         # Timestamped migrations
├── seeds.rb         # Seed data
└── schema.rb        # Auto-generated schema (never edit)

spec/                # RSpec test suite (or test/ for Minitest)
├── models/
├── controllers/
├── requests/
├── services/
├── mailers/
└── factories/       # FactoryBot factories

lib/                 # Utility code, generators, rake tasks
```

## Model Patterns

### ActiveRecord Model with Concerns

```ruby
class User < ApplicationRecord
  include Authenticatable
  include Publishable

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: :password_present?

  enum role: { user: 0, moderator: 1, admin: 2 }

  scope :active, -> { where(active: true) }
  scope :created_after, ->(date) { where('created_at > ?', date) }

  def admin?
    role == 'admin'
  end

  private

  def password_present?
    password.present?
  end
end
```

### Model Concern

```ruby
# app/models/concerns/publishable.rb
module Publishable
  extend ActiveSupport::Concern

  included do
    has_many :publications, as: :publishable
    scope :published, -> { where(published: true) }
  end

  def publish!
    update(published: true, published_at: Time.current)
  end

  def unpublish!
    update(published: false)
  end
end
```

### Validations

```ruby
# Custom validator
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ URI::MailTo::EMAIL_REGEXP
      record.errors.add(attribute, :invalid)
    end
  end
end

# Usage in model
class User < ApplicationRecord
  validates :email, email: true
end
```

## Controller Patterns

### RESTful Controller with Concerns

```ruby
class PostsController < ApplicationController
  include Authenticatable
  include Paginatable

  before_action :require_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user!, only: [:edit, :update, :destroy]

  def index
    @posts = Post.published.page(params[:page])
  end

  def show
    @comments = @post.comments.order(created_at: :desc)
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to @post, notice: 'Post created successfully'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: 'Post updated successfully'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_url, notice: 'Post deleted successfully'
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_user!
    redirect_to root_path unless @post.user == current_user
  end

  def post_params
    params.require(:post).permit(:title, :body, :published)
  end
end
```

### Controller Concern

```ruby
# app/controllers/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :user_signed_in?
  end

  def require_user!
    redirect_to login_path unless current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def user_signed_in?
    current_user.present?
  end
end
```

## Database Migrations

### Migration Pattern

```ruby
class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.boolean :published, default: false
      t.integer :user_id, null: false
      t.integer :view_count, default: 0

      t.timestamps
    end

    add_index :posts, :user_id
    add_index :posts, :published
    add_foreign_key :posts, :users
  end
end
```

### Adding Columns

```ruby
class AddSlugToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :slug, :string
    add_index :posts, :slug, unique: true
  end
end
```

## Authentication with Devise

```ruby
# Gemfile
gem 'devise'

# Generate model
rails generate devise User

# Use Devise in controller
class ProtectedController < ApplicationController
  before_action :authenticate_user!
end

# Sign in current user
sign_in(user)

# Access current user
current_user

# Check if authenticated
user_signed_in?
```

## Turbo/Hotwire Patterns

### Turbo Frame

```erb
<%= turbo_frame_tag "post_#{@post.id}" do %>
  <div class="post">
    <h1><%= @post.title %></h1>
    <p><%= @post.body %></p>
  </div>
<% end %>
```

### Turbo Stream Response

```ruby
def create
  @comment = Comment.new(comment_params)

  if @comment.save
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.append('comments', @comment) }
      format.html { redirect_to @post }
    end
  else
    render :new, status: :unprocessable_entity
  end
end
```

## Testing with RSpec

### Model Spec

```ruby
# spec/models/post_spec.rb
RSpec.describe Post, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:body) }
  end

  describe '#publish!' do
    let(:post) { create(:post, published: false) }

    it 'sets published to true' do
      post.publish!
      expect(post.published).to be(true)
    end

    it 'sets published_at' do
      post.publish!
      expect(post.published_at).to be_present
    end
  end
end
```

### Request Spec

```ruby
# spec/requests/posts_spec.rb
RSpec.describe 'Posts', type: :request do
  describe 'GET /posts' do
    let!(:post) { create(:post) }

    it 'returns 200 OK' do
      get '/posts'
      expect(response).to have_http_status(:ok)
    end

    it 'renders published posts' do
      get '/posts'
      expect(response.body).to include(post.title)
    end
  end

  describe 'POST /posts' do
    let(:user) { create(:user) }

    before { sign_in user }

    it 'creates a post' do
      expect {
        post '/posts', params: { post: attributes_for(:post) }
      }.to change(Post, :count).by(1)
    end

    context 'when unauthenticated' do
      before { sign_out user }

      it 'redirects to login' do
        post '/posts', params: { post: attributes_for(:post) }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
```

### Factory Pattern

```ruby
# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
    published { false }
    association :user
  end
end
```

## Testing with Minitest

```ruby
# test/models/post_test.rb
class PostTest < ActiveSupport::TestCase
  setup do
    @post = posts(:one)
  end

  test 'should be valid' do
    assert @post.valid?
  end

  test 'should have title' do
    @post.title = nil
    assert_not @post.valid?
  end
end

# test/controllers/posts_controller_test.rb
class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
  end

  test 'should get index' do
    get posts_url
    assert_response :success
  end

  test 'should show post' do
    get post_url(@post)
    assert_response :success
  end
end
```

## Background Jobs with ActiveJob

```ruby
class SendEmailJob < ApplicationJob
  queue_as :mailers

  def perform(user_id)
    user = User.find(user_id)
    UserMailer.welcome(user).deliver_later
  end
end

# Enqueue the job
SendEmailJob.perform_later(user.id)

# Schedule for later
SendEmailJob.set(wait: 1.hour).perform_later(user.id)
```

## Routes and Nested Resources

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users

  resources :posts do
    resources :comments, only: [:create, :destroy]
  end

  resources :categories, only: [:index, :show] do
    member do
      get :posts
    end
  end

  namespace :admin do
    resources :users
    resources :posts
  end
end
```

## Conventions

- **Model names**: Singular, CamelCase (User, Post, Comment)
- **Table names**: Plural, snake_case (users, posts, comments)
- **File names**: Singular, snake_case (user.rb, post.rb, comment.rb)
- **Foreign keys**: `{table_singular}_id` (user_id, post_id)
- **Timestamps**: Always include `t.timestamps` in migrations
- **Scopes**: Use lambda syntax, include order/where/limit
- **Concerns**: Extract shared behavior into concerns, include in models/controllers
- **Validations**: Keep in models, use custom validators for complex logic
- **Controllers**: Keep thin, move logic to models or services
- **Views**: Use partials to avoid duplication, always escape output with `<%= %>`
- **Tests**: One test file per model/controller, test happy path + error cases
- **Database**: Always add indexes to foreign keys and frequently queried columns
- **Rake tasks**: Use for one-off or scheduled work, place in `lib/tasks/`

## Agent Task Template

```markdown
# Rails Feature: [Name]

## Requirements
- [ ] Create model with associations
- [ ] Generate migration
- [ ] Add validations
- [ ] Create controller with CRUD actions
- [ ] Add views (index, show, new, edit)
- [ ] Write RSpec tests for model, controller
- [ ] Update routes
- [ ] Add authorization checks
- [ ] Test in dev environment

## Files to Create/Modify
- `app/models/...`
- `app/controllers/...`
- `app/views/...`
- `db/migrate/...`
- `config/routes.rb`
- `spec/...`

## Testing
```bash
rspec spec/models/
rspec spec/controllers/
```

## Verification
- [ ] All tests pass
- [ ] No RuboCop violations
- [ ] Migrations run cleanly
- [ ] Feature works in browser
```
