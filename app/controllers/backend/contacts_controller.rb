module Backend
  class ContactsController < BaseController
    before_action :set_active_nav

    # get: /backend/contacts
    def index
      @contacts = Contact.all
                  .order("#{sort_column} #{sort_direction}")
                  .page(params.fetch(:page, nil))
                  .per(20)
    end

    def sort_column
      (Contact.column_names).include?(params[:sort]) ? params[:sort] : "id"
    end
    helper_method :sort_column

    private

    def set_active_nav
      @active_nav = 'backend_contacts'
    end
  end
end
