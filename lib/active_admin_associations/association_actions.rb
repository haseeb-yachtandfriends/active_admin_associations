module ActiveAdminAssociations
  module AssociationActions
    def association_actions
      member_action :unrelate, :method => :put do
        reflection = resource_class.reflect_on_association(params[:relationship_name].to_sym)
        if reflection.collection?
          related_record = reflection.klass.find(params[:related_id])
          # Do not delete the associated record
          # just unrelate it
          if reflection.options.has_key?(:as) # is a polymorphic relation
            inverse_relationship_name = reflection.options[:as]
            related_record.update_attribute("#{inverse_relationship_name.to_s}_id", nil)
            related_record.update_attribute("#{inverse_relationship_name.to_s}_type", nil)
          else
            # belongs_to relation
            related_record.update_attribute(resource_class.to_s.foreign_key.to_sym, nil)
          end
        else
          resource.update_attribute("#{params[:relationship_name]}_id", nil)
        end
        flash[:notice] = "The record has been unrelated."
        redirect_to request.headers["Referer"].presence || admin_dashboard_url
      end

      member_action :relate, :method => :put do
        reflection = resource_class.reflect_on_association(params[:relationship_name].to_sym)
        if reflection.collection?
          record_to_relate = reflection.klass.find(params[:related_id])
          resource.send(params[:relationship_name]) << record_to_relate
        else
          resource.update_attribute("#{params[:relationship_name]}_id", record_to_relate)
        end
        flash[:notice] = "The record has been related."
        redirect_to request.headers["Referer"].presence || admin_dashboard_url
      end

      member_action :page_related, :method => :get do
        relationship_name = params[:relationship_name].to_sym
        association_config = active_admin_config.form_associations[relationship_name]
        relationship_class = resource_class.reflect_on_association(relationship_name).klass
        association_columns = association_config.fields.presence || relationship_class.content_columns
        render :partial => 'admin/shared/collection_table', :locals => {
          :object             => resource,
          :collection         => resource.send(relationship_name).page(params[:page]),
          :relationship       => relationship_name,
          :columns            => association_columns,
          :relationship_class => relationship_class
        }
      end
    end
  end
end
