# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_07_170422) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "actor_categories", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["actor_id", "category_id"], name: "index_actor_categories_on_actor_id_and_category_id", unique: true
    t.index ["actor_id"], name: "index_actor_categories_on_actor_id"
    t.index ["category_id"], name: "index_actor_categories_on_category_id"
    t.index ["created_by_id"], name: "index_actor_categories_on_created_by_id"
    t.index ["updated_by_id"], name: "index_actor_categories_on_updated_by_id"
  end

  create_table "actor_measures", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.date "date_end"
    t.date "date_start"
    t.bigint "measure_id", null: false
    t.bigint "resource_id"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.decimal "value"
    t.index ["actor_id"], name: "index_actor_measures_on_actor_id"
    t.index ["created_by_id"], name: "index_actor_measures_on_created_by_id"
    t.index ["measure_id"], name: "index_actor_measures_on_measure_id"
    t.index ["resource_id"], name: "index_actor_measures_on_resource_id"
    t.index ["updated_by_id"], name: "index_actor_measures_on_updated_by_id"
  end

  create_table "actors", force: :cascade do |t|
    t.text "activity_summary"
    t.bigint "actortype_id", null: false
    t.text "address"
    t.string "code"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.boolean "draft", default: true
    t.string "email"
    t.decimal "gdp"
    t.boolean "is_archive", default: false
    t.bigint "manager_id"
    t.bigint "parent_id"
    t.string "phone"
    t.decimal "population"
    t.string "prefix"
    t.boolean "private", default: false
    t.boolean "public_api", default: false, null: false
    t.datetime "relationship_updated_at"
    t.bigint "relationship_updated_by_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.string "url"
    t.index ["actortype_id"], name: "index_actors_on_actortype_id"
    t.index ["created_by_id"], name: "index_actors_on_created_by_id"
    t.index ["manager_id"], name: "index_actors_on_manager_id"
    t.index ["parent_id"], name: "index_actors_on_parent_id"
    t.index ["public_api"], name: "index_actors_on_public_api"
    t.index ["updated_by_id"], name: "index_actors_on_updated_by_id"
  end

  create_table "actortype_taxonomies", force: :cascade do |t|
    t.bigint "actortype_id", null: false
    t.datetime "created_at", null: false
    t.bigint "taxonomy_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actortype_id"], name: "index_actortype_taxonomies_on_actortype_id"
    t.index ["taxonomy_id"], name: "index_actortype_taxonomies_on_taxonomy_id"
  end

  create_table "actortypes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "has_members", default: false
    t.boolean "is_active", default: false
    t.boolean "is_target", default: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bookmarks", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.string "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.integer "user_id", null: false
    t.json "view", null: false
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.date "date"
    t.text "description"
    t.boolean "draft", default: false
    t.boolean "is_archive", default: false
    t.integer "manager_id"
    t.integer "parent_id"
    t.boolean "private", default: false
    t.string "reference"
    t.string "short_title"
    t.integer "taxonomy_id"
    t.text "title"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.string "url"
    t.boolean "user_only"
    t.index ["draft"], name: "index_categories_on_draft"
    t.index ["manager_id"], name: "index_categories_on_manager_id"
    t.index ["taxonomy_id"], name: "index_categories_on_taxonomy_id"
  end

  create_table "due_dates", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.boolean "draft", default: false
    t.date "due_date"
    t.integer "indicator_id"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.index ["draft"], name: "index_due_dates_on_draft"
    t.index ["indicator_id"], name: "index_due_dates_on_indicator_id"
  end

  create_table "framework_frameworks", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.integer "framework_id"
    t.integer "other_framework_id"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "framework_taxonomies", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.integer "framework_id", null: false
    t.integer "taxonomy_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["framework_id"], name: "index_framework_taxonomies_on_framework_id"
    t.index ["taxonomy_id"], name: "index_framework_taxonomies_on_taxonomy_id"
  end

  create_table "frameworks", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.text "description"
    t.boolean "has_indicators"
    t.boolean "has_measures"
    t.boolean "has_response"
    t.string "short_title"
    t.text "title", null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "indicators", id: :serial, force: :cascade do |t|
    t.text "annotation_api"
    t.string "code"
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.text "description"
    t.text "description_api"
    t.boolean "draft", default: false
    t.date "end_date"
    t.integer "frequency_months"
    t.boolean "is_archive", default: false
    t.integer "manager_id"
    t.boolean "private", default: false
    t.boolean "public_api", default: false, null: false
    t.string "reference"
    t.datetime "relationship_updated_at"
    t.bigint "relationship_updated_by_id"
    t.boolean "repeat", default: false
    t.text "short_api"
    t.date "start_date"
    t.text "teaser_api"
    t.text "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.index ["created_at"], name: "index_indicators_on_created_at"
    t.index ["draft"], name: "index_indicators_on_draft"
    t.index ["manager_id"], name: "index_indicators_on_manager_id"
    t.index ["public_api"], name: "index_indicators_on_public_api"
  end

  create_table "measure_actors", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.date "date_end"
    t.date "date_start"
    t.bigint "measure_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.decimal "value"
    t.index ["actor_id"], name: "index_measure_actors_on_actor_id"
    t.index ["created_by_id"], name: "index_measure_actors_on_created_by_id"
    t.index ["measure_id"], name: "index_measure_actors_on_measure_id"
    t.index ["updated_by_id"], name: "index_measure_actors_on_updated_by_id"
  end

  create_table "measure_categories", id: :serial, force: :cascade do |t|
    t.integer "category_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.integer "measure_id"
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "updated_by_id"
    t.index ["measure_id", "category_id"], name: "index_measure_categories_on_measure_id_and_category_id", unique: true
    t.index ["updated_by_id"], name: "index_measure_categories_on_updated_by_id"
  end

  create_table "measure_indicators", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.integer "indicator_id"
    t.integer "measure_id"
    t.bigint "supportlevel_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["measure_id", "indicator_id"], name: "index_measure_indicators_on_measure_id_and_indicator_id", unique: true
  end

  create_table "measure_measures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "measure_id", null: false
    t.bigint "other_measure_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["created_by_id"], name: "index_measure_measures_on_created_by_id"
    t.index ["measure_id", "other_measure_id"], name: "index_measure_measures_on_measure_id_and_other_measure_id", unique: true
    t.index ["measure_id"], name: "index_measure_measures_on_measure_id"
    t.index ["other_measure_id"], name: "index_measure_measures_on_other_measure_id"
    t.index ["updated_by_id"], name: "index_measure_measures_on_updated_by_id"
  end

  create_table "measure_resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "measure_id", null: false
    t.bigint "resource_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["created_by_id"], name: "index_measure_resources_on_created_by_id"
    t.index ["measure_id", "resource_id"], name: "index_measure_resources_on_measure_id_and_resource_id", unique: true
    t.index ["measure_id"], name: "index_measure_resources_on_measure_id"
    t.index ["resource_id"], name: "index_measure_resources_on_resource_id"
    t.index ["updated_by_id"], name: "index_measure_resources_on_updated_by_id"
  end

  create_table "measures", id: :serial, force: :cascade do |t|
    t.decimal "amount"
    t.string "amount_comment"
    t.string "code"
    t.string "comment"
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.string "date_comment"
    t.datetime "date_end", precision: nil
    t.datetime "date_start", precision: nil
    t.text "description"
    t.boolean "draft", default: false
    t.boolean "has_reference_landbased_ml"
    t.text "indicator_summary"
    t.boolean "is_archive", default: false
    t.bigint "measuretype_id"
    t.boolean "notifications", default: true
    t.text "outcome"
    t.bigint "parent_id"
    t.boolean "private", default: false
    t.boolean "public_api", default: false, null: false
    t.text "quote_api"
    t.string "reference_landbased_ml"
    t.string "reference_ml"
    t.datetime "relationship_updated_at"
    t.bigint "relationship_updated_by_id"
    t.text "source_api"
    t.string "status_comment"
    t.string "status_lbs_protocol"
    t.string "target_comment"
    t.text "target_date"
    t.text "target_date_comment"
    t.text "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.string "url"
    t.index ["draft"], name: "index_measures_on_draft"
    t.index ["measuretype_id"], name: "index_measures_on_measuretype_id"
    t.index ["parent_id"], name: "index_measures_on_parent_id"
    t.index ["public_api"], name: "index_measures_on_public_api"
  end

  create_table "measuretype_taxonomies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "measuretype_id", null: false
    t.bigint "taxonomy_id", null: false
    t.datetime "updated_at", null: false
    t.index ["measuretype_id"], name: "index_measuretype_taxonomies_on_measuretype_id"
    t.index ["taxonomy_id"], name: "index_measuretype_taxonomies_on_taxonomy_id"
  end

  create_table "measuretypes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "has_parent", default: true
    t.boolean "has_target", default: true
    t.boolean "notifications", default: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "member_id", null: false
    t.bigint "memberof_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["created_by_id"], name: "index_memberships_on_created_by_id"
    t.index ["member_id", "memberof_id"], name: "index_memberships_on_member_id_and_memberof_id", unique: true
    t.index ["member_id"], name: "index_memberships_on_member_id"
    t.index ["memberof_id"], name: "index_memberships_on_memberof_id"
    t.index ["updated_by_id"], name: "index_memberships_on_updated_by_id"
  end

  create_table "pages", id: :serial, force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.boolean "draft", default: false
    t.string "menu_title"
    t.integer "order"
    t.boolean "private", default: false
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.index ["draft"], name: "index_pages_on_draft"
    t.index ["private"], name: "index_pages_on_private"
  end

  create_table "progress_reports", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.text "description"
    t.boolean "document_public"
    t.string "document_url"
    t.boolean "draft"
    t.integer "due_date_id"
    t.integer "indicator_id"
    t.text "title"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.index ["due_date_id"], name: "index_progress_reports_on_due_date_id"
    t.index ["indicator_id"], name: "index_progress_reports_on_indicator_id"
  end

  create_table "recommendation_categories", id: :serial, force: :cascade do |t|
    t.integer "category_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.integer "recommendation_id"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "recommendation_indicators", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.integer "indicator_id"
    t.integer "recommendation_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["indicator_id"], name: "index_recommendation_indicators_on_indicator_id"
    t.index ["recommendation_id"], name: "index_recommendation_indicators_on_recommendation_id"
  end

  create_table "recommendation_measures", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.integer "measure_id"
    t.integer "recommendation_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["measure_id"], name: "index_recommendation_measures_on_measure_id"
    t.index ["recommendation_id"], name: "index_recommendation_measures_on_recommendation_id"
  end

  create_table "recommendation_recommendations", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.integer "other_recommendation_id"
    t.integer "recommendation_id"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "recommendations", id: :serial, force: :cascade do |t|
    t.boolean "accepted"
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.text "description"
    t.boolean "draft", default: false
    t.integer "framework_id"
    t.text "reference", null: false
    t.text "response"
    t.text "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.index ["draft"], name: "index_recommendations_on_draft"
    t.index ["framework_id"], name: "index_recommendations_on_framework_id"
  end

  create_table "resources", force: :cascade do |t|
    t.datetime "access_date", precision: nil
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.boolean "draft", default: true
    t.boolean "is_archive", default: false
    t.boolean "private", default: false
    t.datetime "publication_date", precision: nil
    t.bigint "resourcetype_id", null: false
    t.text "status"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.text "url"
    t.index ["created_by_id"], name: "index_resources_on_created_by_id"
    t.index ["resourcetype_id"], name: "index_resources_on_resourcetype_id"
    t.index ["updated_by_id"], name: "index_resources_on_updated_by_id"
  end

  create_table "resourcetypes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.string "friendly_name", null: false
    t.string "name", null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "taxonomies", id: :serial, force: :cascade do |t|
    t.boolean "allow_multiple"
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.integer "framework_id"
    t.integer "groups_measures_default"
    t.integer "groups_recommendations_default"
    t.boolean "has_date"
    t.boolean "has_manager", default: false
    t.boolean "is_smart"
    t.integer "parent_id"
    t.integer "priority"
    t.boolean "tags_measures"
    t.boolean "tags_users"
    t.text "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.index ["framework_id"], name: "index_taxonomies_on_framework_id"
  end

  create_table "user_actors", id: :serial, force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "user_id", null: false
    t.index ["actor_id"], name: "index_user_actors_on_actor_id"
    t.index ["created_by_id"], name: "index_user_actors_on_created_by_id"
    t.index ["updated_by_id"], name: "index_user_actors_on_updated_by_id"
    t.index ["user_id", "actor_id"], name: "index_user_actors_on_user_id_and_actor_id", unique: true
    t.index ["user_id"], name: "index_user_actors_on_user_id"
  end

  create_table "user_categories", id: :serial, force: :cascade do |t|
    t.integer "category_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
  end

  create_table "user_measures", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "measure_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "user_id", null: false
    t.index ["created_by_id"], name: "index_user_measures_on_created_by_id"
    t.index ["measure_id"], name: "index_user_measures_on_measure_id"
    t.index ["updated_by_id"], name: "index_user_measures_on_updated_by_id"
    t.index ["user_id", "measure_id"], name: "index_user_measures_on_user_id_and_measure_id", unique: true
    t.index ["user_id"], name: "index_user_measures_on_user_id"
  end

  create_table "user_roles", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.integer "role_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.integer "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.boolean "allow_password_change", default: true
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.datetime "current_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at", precision: nil
    t.inet "last_sign_in_ip"
    t.string "name"
    t.string "provider", default: "email", null: false
    t.datetime "relationship_updated_at"
    t.bigint "relationship_updated_by_id"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.json "tokens"
    t.string "uid", default: "", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "actor_categories", "actors"
  add_foreign_key "actor_categories", "categories"
  add_foreign_key "actor_categories", "users", column: "created_by_id"
  add_foreign_key "actor_categories", "users", column: "updated_by_id"
  add_foreign_key "actor_measures", "actors"
  add_foreign_key "actor_measures", "measures"
  add_foreign_key "actor_measures", "resources"
  add_foreign_key "actor_measures", "users", column: "created_by_id"
  add_foreign_key "actor_measures", "users", column: "updated_by_id"
  add_foreign_key "actors", "actors", column: "parent_id"
  add_foreign_key "actors", "actortypes"
  add_foreign_key "actors", "users", column: "manager_id"
  add_foreign_key "actors", "users", column: "relationship_updated_by_id"
  add_foreign_key "actortype_taxonomies", "actortypes"
  add_foreign_key "actortype_taxonomies", "taxonomies"
  add_foreign_key "framework_frameworks", "frameworks"
  add_foreign_key "framework_frameworks", "frameworks", column: "other_framework_id"
  add_foreign_key "framework_taxonomies", "frameworks"
  add_foreign_key "framework_taxonomies", "taxonomies"
  add_foreign_key "indicators", "users", column: "relationship_updated_by_id"
  add_foreign_key "measure_actors", "actors"
  add_foreign_key "measure_actors", "measures"
  add_foreign_key "measure_actors", "users", column: "created_by_id"
  add_foreign_key "measure_actors", "users", column: "updated_by_id"
  add_foreign_key "measure_categories", "users", column: "updated_by_id"
  add_foreign_key "measure_measures", "measures"
  add_foreign_key "measure_measures", "measures", column: "other_measure_id"
  add_foreign_key "measure_measures", "users", column: "created_by_id"
  add_foreign_key "measure_measures", "users", column: "updated_by_id"
  add_foreign_key "measure_resources", "measures"
  add_foreign_key "measure_resources", "resources"
  add_foreign_key "measure_resources", "users", column: "created_by_id"
  add_foreign_key "measure_resources", "users", column: "updated_by_id"
  add_foreign_key "measures", "measures", column: "parent_id"
  add_foreign_key "measures", "measuretypes"
  add_foreign_key "measures", "users", column: "relationship_updated_by_id"
  add_foreign_key "measuretype_taxonomies", "measuretypes"
  add_foreign_key "measuretype_taxonomies", "taxonomies"
  add_foreign_key "memberships", "actors", column: "member_id"
  add_foreign_key "memberships", "actors", column: "memberof_id"
  add_foreign_key "memberships", "users", column: "created_by_id"
  add_foreign_key "memberships", "users", column: "updated_by_id"
  add_foreign_key "recommendation_indicators", "indicators"
  add_foreign_key "recommendation_indicators", "recommendations"
  add_foreign_key "recommendation_recommendations", "recommendations"
  add_foreign_key "recommendation_recommendations", "recommendations", column: "other_recommendation_id"
  add_foreign_key "recommendations", "frameworks"
  add_foreign_key "resources", "resourcetypes"
  add_foreign_key "taxonomies", "frameworks"
  add_foreign_key "user_actors", "actors"
  add_foreign_key "user_actors", "users"
  add_foreign_key "user_actors", "users", column: "created_by_id"
  add_foreign_key "user_actors", "users", column: "updated_by_id"
  add_foreign_key "user_measures", "measures"
  add_foreign_key "user_measures", "users"
  add_foreign_key "user_measures", "users", column: "created_by_id"
  add_foreign_key "user_measures", "users", column: "updated_by_id"
  add_foreign_key "users", "users", column: "relationship_updated_by_id"
end
