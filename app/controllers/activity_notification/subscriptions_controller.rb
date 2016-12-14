module ActivityNotification
  # Controller to manage subscriptions.
  class SubscriptionsController < ActivityNotification.config.parent_controller.constantize
    # Include CommonController to select target and define common methods
    include CommonController
    before_action :set_subscription, except: [:index, :create]

    # Shows subscription index of the target.
    #
    # GET /:target_type/:target_id/subscriptions
    # @overload index(params)
    #   @param [Hash] params Request parameter options for subscription index
    #   @option params [String] :filter          (nil)     Filter option to load subscription index (Nothing as all, 'configured' or 'unconfigured')
    #   @option params [String] :limit           (nil)     Limit to query for subscriptions
    #   @option params [String] :reverse         ('false') If subscription index and unconfigured notification keys will be ordered as earliest first
    #   @option params [String] :filtered_by_key (nil)     Key of the subscription for filter
    #   @return [Responce] HTML view as default or JSON of subscription index with json format parameter
    def index
      set_index_options
      load_index if params[:reload].to_s.to_boolean(true)
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: { subscriptions: @subscriptions, unconfigured_notification_keys: @notification_keys } }
      end
    end

    # Creates a subscription.
    #
    # POST /:target_type/:target_id/subscriptions
    #
    # @overload create(params)
    #   @param [Hash] params Request parameters
    #   @option params [String] :subscription                              Subscription parameters
    #   @option params [String] :subscription[:key]                        Key of the subscription
    #   @option params [String] :subscription[:subscribing]          (nil) If the target will subscribe to the notification
    #   @option params [String] :subscription[:subscribing_to_email] (nil) If the target will subscribe to the notification email
    #   @option params [String] :filter          (nil)     Filter option to load subscription index (Nothing as all, 'configured' or 'unconfigured')
    #   @option params [String] :limit           (nil)     Limit to query for subscriptions
    #   @option params [String] :reverse         ('false') If subscription index and unconfigured notification keys will be ordered as earliest first
    #   @option params [String] :filtered_by_key (nil)     Key of the subscription for filter
    #   @return [Responce] JavaScript view for ajax request or redirects to back as default
    def create
      @target.create_subscription(subscription_params)
      return_back_or_ajax
    end

    # Shows a subscription.
    #
    # GET /:target_type/:target_id/subscriptions/:id
    # @overload show(params)
    #   @param [Hash] params Request parameters
    #   @return [Responce] HTML view as default
    def show
    end
  
    # Deletes a subscription.
    #
    # DELETE /:target_type/:target_id/subscriptions/:id
    #
    # @overload destroy(params)
    #   @param [Hash] params Request parameters
    #   @option params [String] :filter          (nil)     Filter option to load subscription index (Nothing as all, 'configured' or 'unconfigured')
    #   @option params [String] :limit           (nil)     Limit to query for subscriptions
    #   @option params [String] :reverse         ('false') If subscription index and unconfigured notification keys will be ordered as earliest first
    #   @option params [String] :filtered_by_key (nil)     Key of the subscription for filter
    #   @return [Responce] JavaScript view for ajax request or redirects to back as default
    def destroy
      @subscription.destroy
      return_back_or_ajax
    end

    # Subscribes to the notification.
    #
    # POST /:target_type/:target_id/subscriptions/:id/subscribe
    # @overload open(params)
    #   @param [Hash] params Request parameters
    #   @option params [String] :filter          (nil)     Filter option to load subscription index (Nothing as all, 'configured' or 'unconfigured')
    #   @option params [String] :limit           (nil)     Limit to query for subscriptions
    #   @option params [String] :reverse         ('false') If subscription index and unconfigured notification keys will be ordered as earliest first
    #   @option params [String] :filtered_by_key (nil)     Key of the subscription for filter
    #   @return [Responce] JavaScript view for ajax request or redirects to back as default
    def subscribe
      @subscription.subscribe
      return_back_or_ajax
    end

    # Unsubscribes to the notification.
    #
    # POST /:target_type/:target_id/subscriptions/:id/unsubscribe
    # @overload open(params)
    #   @param [Hash] params Request parameters
    #   @option params [String] :filter          (nil)     Filter option to load subscription index (Nothing as all, 'configured' or 'unconfigured')
    #   @option params [String] :limit           (nil)     Limit to query for subscriptions
    #   @option params [String] :reverse         ('false') If subscription index and unconfigured notification keys will be ordered as earliest first
    #   @option params [String] :filtered_by_key (nil)     Key of the subscription for filter
    #   @return [Responce] JavaScript view for ajax request or redirects to back as default
    def unsubscribe
      @subscription.unsubscribe
      return_back_or_ajax
    end

    # Subscribes to the notification email.
    #
    # POST /:target_type/:target_id/subscriptions/:id/subscribe_email
    # @overload open(params)
    #   @param [Hash] params Request parameters
    #   @option params [String] :filter          (nil)     Filter option to load subscription index (Nothing as all, 'configured' or 'unconfigured')
    #   @option params [String] :limit           (nil)     Limit to query for subscriptions
    #   @option params [String] :reverse         ('false') If subscription index and unconfigured notification keys will be ordered as earliest first
    #   @option params [String] :filtered_by_key (nil)     Key of the subscription for filter
    #   @return [Responce] JavaScript view for ajax request or redirects to back as default
    def subscribe_to_email
      @subscription.subscribe_to_email
      return_back_or_ajax
    end

    # Unsubscribes to the notification email.
    #
    # POST /:target_type/:target_id/subscriptions/:id/unsubscribe_email
    # @overload open(params)
    #   @param [Hash] params Request parameters
    #   @option params [String] :filter          (nil)     Filter option to load subscription index (Nothing as all, 'configured' or 'unconfigured')
    #   @option params [String] :limit           (nil)     Limit to query for subscriptions
    #   @option params [String] :reverse         ('false') If subscription index and unconfigured notification keys will be ordered as earliest first
    #   @option params [String] :filtered_by_key (nil)     Key of the subscription for filter
    #   @return [Responce] JavaScript view for ajax request or redirects to back as default
    def unsubscribe_to_email
      @subscription.unsubscribe_to_email
      return_back_or_ajax
    end

    protected

      # Sets @subscription instance variable from request parameters.
      # @api protected
      # @return [Object] Subscription instance (Returns HTTP 403 when the target of subscription is different from specified target by request parameter)
      def set_subscription
        @subscription = Subscription.includes(:target).find_by_id!(params[:id])
        if @target.present? && @subscription.target != @target
          render plain: "403 Forbidden: Wrong target", status: 403
        end
      end

      # Only allow a trusted parameter "white list" through.
      def subscription_params
        params.require(:subscription).permit(:key, :subscribing, :subscribing_to_email)
      end

      # Sets options to load subscription index from request parameters.
      # @api protected
      # @return [Hash] options to load subscription index
      def set_index_options
        limit          = params[:limit].to_i > 0 ? params[:limit].to_i : nil
        reverse        = params[:reverse].present? ?
                           params[:reverse].to_s.to_boolean(false) : nil
        @index_options = params.permit(:filter, :filtered_by_key)
                               .to_h.symbolize_keys.merge(limit: limit, reverse: reverse)
      end

      # Loads subscription index with request parameters.
      # @api protected
      # @param [Hash] params Request parameter options for subscription index
      # @return [Array] Array of subscription index
      def load_index
        case @index_options[:filter]
        when :configured, 'configured'
          @subscriptions = @target.subscription_index(@index_options.merge(with_target: true))
          @notification_keys = nil
        when :unconfigured, 'unconfigured'
          @subscriptions = nil
          @notification_keys = @target.notification_keys(@index_options.merge(filter: :unconfigured))
        else
          @subscriptions = @target.subscription_index(@index_options.merge(with_target: true))
          @notification_keys = @target.notification_keys(@index_options.merge(filter: :unconfigured))
        end
      end

      # Returns controller path.
      # This method is called from target_view_path method and can be overriden.
      # @api protected
      # @return [String] "activity_notification/subscriptions" as controller path
      def controller_path
        "activity_notification/subscriptions"
      end

  end
end