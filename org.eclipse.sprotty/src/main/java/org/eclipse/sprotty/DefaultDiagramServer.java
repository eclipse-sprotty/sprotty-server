/********************************************************************************
 * Copyright (c) 2017-2019 TypeFox and others.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the Eclipse
 * Public License v. 2.0 are satisfied: GNU General Public License, version 2
 * with the GNU Classpath Exception which is available at
 * https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 ********************************************************************************/
package org.eclipse.sprotty;

import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;

import javax.inject.Inject;

import org.apache.log4j.Logger;
import org.eclipse.sprotty.util.RejectException;

import com.google.common.base.Strings;

import static org.eclipse.sprotty.DiagramOptions.*;

/**
 * The default diagram server implementation. It realizes the same message protocol as the
 * TypeScript class {@code LocalModelSource}.
 */
public class DefaultDiagramServer implements IDiagramServer {
	
	private static final Logger LOG = Logger.getLogger(DefaultDiagramServer.class);
	
	protected static AtomicLong nextRequestId = new AtomicLong();
	
	private String clientId;
	
	private SModelRoot currentRoot;
	
	private Map<String, String> options;
	
	private Consumer<ActionMessage> remoteEndpoint;
	
	private IModelUpdateListener modelUpdateListener;
	
	private ILayoutEngine layoutEngine;
	
	private ComputedBoundsApplicator computedBoundsApplicator;
	
	private IPopupModelFactory popupModelFactory;
	
	private IDiagramSelectionListener diagramSelectionListener;

	private IDiagramExpansionListener diagramExpansionListener;

	private IDiagramOpenListener diagramOpenListener;

	private SModelCloner smodelCloner;
	
	private final Map<String, CompletableFuture<ResponseAction>> requests = new HashMap<>();
	
	private final Set<String> expandedElements = new HashSet<>();

	private final Set<String> selectedElements = new HashSet<>();
	
	private Object modelLock = new Object();

	private int revision = 0;
	
	private ServerStatus status;
	
	private String lastSubmittedModelType;

	public DefaultDiagramServer() {
		currentRoot = new SModelRoot();
		currentRoot.setType("NONE");
		currentRoot.setId("ROOT");
	}
	
	public DefaultDiagramServer(String clientId) {
		this();
		this.clientId = clientId;
	}
	
	@Override
	public IDiagramState getDiagramState() {
		return new DefaultDiagramState(this);
	}

	@Override
	public String getClientId() {
		return clientId;
	}
	
	public void setClientId(String clientId) {
		this.clientId = clientId;
	}
	
	@Override
	public Consumer<ActionMessage> getRemoteEndpoint() {
		return remoteEndpoint;
	}
	
	@Override
	public void setRemoteEndpoint(Consumer<ActionMessage> remoteEndpoint) {
		this.remoteEndpoint = remoteEndpoint;
	}
	
	protected IModelUpdateListener getModelUpdateListener() {
		return modelUpdateListener;
	}
	
	@Inject
	public void setModelUpdateListener(IModelUpdateListener listener) {
		this.modelUpdateListener = listener;
	}
	
	protected ILayoutEngine getLayoutEngine() {
		return layoutEngine;
	}
	
	@Inject
	public void setLayoutEngine(ILayoutEngine engine) {
		this.layoutEngine = engine;
	}
	
	protected ComputedBoundsApplicator getComputedBoundsApplicator() {
		return computedBoundsApplicator;
	}
	
	@Inject
	public void setComputedBoundsApplicator(ComputedBoundsApplicator computedBoundsApplicator) {
		this.computedBoundsApplicator = computedBoundsApplicator;
	}
	
	protected IPopupModelFactory getPopupModelFactory() {
		return popupModelFactory;
	}
	
	@Inject
	public void setPopupModelFactory(IPopupModelFactory factory) {
		this.popupModelFactory = factory;
	}
	
	protected IDiagramSelectionListener getSelectionListener() {
		return diagramSelectionListener;
	}
	
	@Inject
	public void setSelectionListener(IDiagramSelectionListener listener) {
		this.diagramSelectionListener = listener;
	}
	
	public IDiagramExpansionListener getExpansionListener() {
		return diagramExpansionListener;
	}
	
	@Inject
	public void setExpansionListener(IDiagramExpansionListener diagramExpansionListener) {
		this.diagramExpansionListener = diagramExpansionListener;
	}
	
	public IDiagramOpenListener getOpenListener() {
		return diagramOpenListener;
	}
	
	@Inject
	public void setOpenListener(IDiagramOpenListener diagramOpenListener) {
		this.diagramOpenListener = diagramOpenListener;
	}
	
	protected SModelCloner getSModelCloner() {
		return this.smodelCloner;	
	}
	
	@Inject 
	protected void setSModelCloner(SModelCloner smodelCloner) {
		this.smodelCloner = smodelCloner;
	}
	
	@Override
	public void dispatch(Action action) {
		Consumer<ActionMessage> remoteEndpoint = getRemoteEndpoint();
		if (remoteEndpoint != null) {
			remoteEndpoint.accept(new ActionMessage(getClientId(), action));
			if (action instanceof SelectAction) {
				updateSelection((SelectAction) action);
			} else if (action instanceof SelectAllAction) {
				updateSelection((SelectAllAction) action);
			}
		}
	}
	
	@SuppressWarnings("unchecked")
	@Override
	public <Res extends ResponseAction> CompletableFuture<Res> request(RequestAction<Res> action) {
		if (Strings.isNullOrEmpty(action.getRequestId())) {
			action.setRequestId(generateRequestId());
		}
		CompletableFuture<Res> future = new CompletableFuture<>();
		this.requests.put(action.getRequestId(), (CompletableFuture<ResponseAction>) future);
		this.dispatch(action);
		return future;
	}
	
	public void rejectRemoteRequest(Action action, Throwable exception) {
		if (action instanceof RequestAction) {
			RequestAction<?> request = (RequestAction<?>) action;
			if (!Strings.isNullOrEmpty(request.getRequestId())) {
				String message = exception.getMessage();
				if (message == null)
					message = exception.getClass().getSimpleName();
				dispatch(new RejectAction(message, request.getRequestId()));
			}
		}
	}
	
	/**
	 * Generate a unique {@code requestId} for a request action.
	 */
	protected String generateRequestId() {
	    return "server_" + nextRequestId.incrementAndGet();
	}
	
	@Override
	public SModelRoot getModel() {
		return currentRoot;
	}
	
	@Override
	public CompletableFuture<Void> setModel(SModelRoot newRoot) {
		if (newRoot == null)
			throw new NullPointerException();
		synchronized(modelLock) {
			newRoot.setRevision(++revision);
			currentRoot = newRoot;
		}
		return submitModel(newRoot, false, null);
	}
	
	@Override
	public CompletableFuture<Void> updateModel(SModelRoot newRoot) {
		if (newRoot == null)
			throw new IllegalArgumentException("updateModel() cannot be called with null");
		synchronized(modelLock) {
			currentRoot = newRoot;
			newRoot.setRevision(++revision);
		}
		return submitModel(newRoot, true, null);
	}
	
	public CompletableFuture<Void> updateModel(SModelRoot newRoot, Action cause) {
		if (newRoot == null)
			throw new IllegalArgumentException("updateModel() cannot be called with null");
		synchronized(modelLock) {
			currentRoot = newRoot;
			newRoot.setRevision(++revision);
		}
		return submitModel(newRoot, true, cause);
	}
	
	public ServerStatus getStatus() {
		return status;
	}
	
	public void setStatus(ServerStatus status) {
		this.status = status;
		dispatch(new ServerStatusAction(status));
	}
	
	@Override
	public Map<String, String> getOptions() {
		if (options == null) {
			options = new LinkedHashMap<>();
		}
		return options;
	}
	
	protected void setOptions(Map<String, String> options) {
		this.options = new LinkedHashMap<>(options);
	}
	
	/**
	 * Whether the client needs to compute the layout of parts of the model. This affects the behavior or
	 * {@link #submitModel(SModelRoot, boolean, Action)}.
	 * 
	 * <p>This setting is determined by the <code>ViewerOptions</code> that are received with the
	 * {@link RequestModelAction} from the client. If the client does not specify whether it needs
	 * local layout, the default value is <code>true</code>.</p>
	 * 
	 * <p>Subclasses can override this method to obtain different behavior depending on the given model.</p>
	 */
	protected boolean needsClientLayout(SModelRoot root) {
		String needsClientLayout = getOptions().get(OPTION_NEEDS_CLIENT_LAYOUT);
		if (needsClientLayout != null && !needsClientLayout.isEmpty()) {
			return Boolean.parseBoolean(needsClientLayout);
		}
		return true;
	}
	
	/**
	 * Whether the server needs to compute the layout of parts of the model. This affects the behavior or
	 * {@link #submitModel(SModelRoot, boolean, Action)}.
	 * 
	 * <p>This setting is determined by the <code>ViewerOptions</code> that are received with the
	 * {@link RequestModelAction} from the client. If the client does not specify whether it needs
	 * server layout, the default value is <code>false</code>.</p>
	 * 
	 * <p>Subclasses can override this method to obtain different behavior depending on the given
	 * model and action.</p>
	 */
	protected boolean needsServerLayout(SModelRoot root, Action cause) {
		String needsServerLayout = getOptions().get(OPTION_NEEDS_SERVER_LAYOUT);
		if (needsServerLayout != null && !needsServerLayout.isEmpty()) {
			boolean value = Boolean.parseBoolean(needsServerLayout);
			if (value && getLayoutEngine() == null) {
				LOG.error("Client demands server-side layout but the ILayoutEngine is not set. Switching server-side layout off.");
				value = false;
			}
			return value;
		}
		return false;
	}
		
	/**
	 * Submit a new or updated model to the client. If client layout is required, a {@link RequestBoundsAction}
	 * is sent, otherwise either a {@link SetModelAction} or an {@link UpdateModelAction} is sent depending on
	 * the {@code update} parameter.
	 */
	protected CompletableFuture<Void> submitModel(SModelRoot newRoot, boolean update, Action cause) {
		if (needsClientLayout(newRoot)) {
			if (!needsServerLayout(newRoot, cause)) {
				// In this case the client won't send us the computed bounds
				dispatch(new RequestBoundsAction(newRoot));
				updateSelection(newRoot, update, cause);
				IModelUpdateListener listener = getModelUpdateListener();
				if (listener != null)
					listener.modelSubmitted(newRoot, this);
			} else {
				return request(new RequestBoundsAction(newRoot)).handle((response, exception) -> {
					if (exception != null) {
						rejectRemoteRequest(cause, exception);
						LOG.error("RequestBoundsAction failed with an exception.", exception);
					} else {
						try {
							SModelRoot model = handle(response);
							if (model != null)
								doSubmitModel(model, update, cause);
						} catch (Exception exc) {
							rejectRemoteRequest(cause, exc);
							LOG.error("Exception while processing ComputedBoundsAction.", exc);
						}
					}
					return null;
				});
			}
		} else {
			doSubmitModel(newRoot, update, cause);
		}
		return CompletableFuture.completedFuture(null);
	}
	
	private void doSubmitModel(SModelRoot newRoot, boolean update, Action cause) {
		ILayoutEngine layoutEngine = getLayoutEngine();
		if (needsServerLayout(newRoot, cause)) {
			layoutEngine.layout(newRoot, cause);
		}
		synchronized (modelLock) {
			if (newRoot.getRevision() == revision) {
				String modelType = newRoot.getType();
				if (cause instanceof RequestModelAction
						&& !Strings.isNullOrEmpty(((RequestModelAction) cause).getRequestId())) {
					RequestModelAction request = (RequestModelAction) cause;
					SetModelAction response = new SetModelAction(newRoot);
					response.setResponseId(request.getRequestId());
		            dispatch(response);
		        } else if (update && modelType != null && modelType.equals(lastSubmittedModelType)) {
					dispatch(new UpdateModelAction(newRoot, cause));
				} else {
					dispatch(new SetModelAction(newRoot));
				}
				lastSubmittedModelType = modelType;
				updateSelection(newRoot, update, cause);
				IModelUpdateListener listener = getModelUpdateListener();
				if (listener != null) {
					listener.modelSubmitted(newRoot, this);
				}
			}
		}
	}

	private void updateSelection(SelectAction action) {
		boolean selectionChanged = false;
		if (action.getDeselectedElementsIDs() != null) {
			selectionChanged |= selectedElements.removeAll(action.getDeselectedElementsIDs());
		}
		if (action.getSelectedElementsIDs() != null) {
			selectionChanged |= selectedElements.addAll(action.getSelectedElementsIDs());
		}

		if (selectionChanged)
			fireSelectionChanged(action);
	}

	private void updateSelection(SelectAllAction action) {
		int previousSize = selectedElements.size();
		if (action.isSelect()) {
			selectedElements.clear();
			selectedElements.addAll(new SModelIndex(getModel()).allIds());
		} else {
			selectedElements.clear();
		}

		if (selectedElements.size() != previousSize)
			fireSelectionChanged(action);
	}

	protected void updateSelection(SModelRoot newRoot, boolean update, Action cause) {
		boolean selectionChanged = false;
		if (update) {
			selectionChanged = selectedElements.retainAll(new SModelIndex(newRoot).allIds());
		} else {
			selectedElements.clear();
		}

		if (selectionChanged)
			fireSelectionChanged(cause);
	}

	private void fireSelectionChanged(Action cause) {
		IDiagramSelectionListener selectionListener = getSelectionListener();
		if (selectionListener != null) {
			selectionListener.selectionChanged(cause, this);
		}
	}
	
	@Override
	public void accept(ActionMessage message) {
		String clientId = message.getClientId();
		if (clientId == null || clientId.equals(this.getClientId())) {
			Action action = message.getAction();
			if (action instanceof ResponseAction) {
				ResponseAction response = (ResponseAction) action;
				String id = response.getResponseId();
				if (!Strings.isNullOrEmpty(id)) {
					CompletableFuture<ResponseAction> future = requests.get(id);
		            if (future != null) {
		                this.requests.remove(id);
		                if (response instanceof RejectAction) {
		                	RejectAction rejectAction = (RejectAction) response;
		                	future.completeExceptionally(new RejectException(rejectAction));
		                	LOG.warn("Request with id " + response.getResponseId() + " failed: "
		                			+ rejectAction.getMessage());
		                } else {
		                	future.complete(response);
		                }
		                return;
		            }
		            if (LOG.isInfoEnabled()) {
		            	LOG.info("No matching request for response:\n" + action);
		            }
				}
	        }
			handleAction(action);
		}
	}

	protected void handleAction(Action action) {
		switch (action.getKind()) {
			case RequestModelAction.KIND:
				handle((RequestModelAction) action);
				break;
			case RequestPopupModelAction.KIND:
				handle((RequestPopupModelAction) action);
				break;
			case ComputedBoundsAction.KIND:
				handle((ComputedBoundsAction) action);
				break;
			case SelectAction.KIND:
				handle((SelectAction) action);
				break;
			case SelectAllAction.KIND:
				handle((SelectAllAction) action);
				break;
			case CollapseExpandAction.KIND:
				handle((CollapseExpandAction) action);
				break;
			case CollapseExpandAllAction.KIND:
				handle((CollapseExpandAllAction) action);
				break;
			case OpenAction.KIND:
				handle((OpenAction) action);
				break;
			case LayoutAction.KIND:
				handle((LayoutAction) action);
				break;
		}
	}
	
	/**
	 * Called when a {@link RequestModelAction} is received.
	 */
	protected void handle(RequestModelAction request) {
		try {
			copyOptions(request);
			submitModel(getModel(), false, request);
		} catch (Exception exc) {
			rejectRemoteRequest(request, exc);
			LOG.error("Error while processing RequestModelAction.", exc);
		}
	}
	
	/**
	 * Copy the request options to this server instance, if present.
	 */
	protected void copyOptions(RequestModelAction request) {
		Map<String, String> options = request.getOptions();
		if (options != null) {
			getOptions().putAll(options);
		}
	}
	
	/**
	 * Called when a {@link ComputedBoundsAction} is received.
	 */
	protected SModelRoot handle(ComputedBoundsAction computedBounds) {
		synchronized(modelLock) {
			SModelRoot model = getModel();
			if (model.getRevision() == computedBounds.getRevision()) {
				getComputedBoundsApplicator().applyBounds(model, computedBounds);
				return model;
			}
		}
		return null;
	}
	
	/**
	 * Called when a {@link RequestPopupModelAction} is received.
	 */
	protected void handle(RequestPopupModelAction request) {
		try {
			SModelRoot model = getModel();
			SModelElement element = SModelIndex.find(model, request.getElementId());
			IPopupModelFactory factory = getPopupModelFactory();
			if (factory != null) {
				SModelRoot popupModel = factory.createPopupModel(element, request, this);
				if (popupModel != null) {
					SetPopupModelAction response = new SetPopupModelAction(popupModel);
					response.setResponseId(request.getRequestId());
					dispatch(response);
					return;
				}
			}
			if (!Strings.isNullOrEmpty(request.getRequestId())) {
				dispatch(new RejectAction("No popup model available.", request.getRequestId()));
			}
		} catch (Exception exc) {
			rejectRemoteRequest(request, exc);
			LOG.error("Error while processing RequestPopupModelAction.", exc);
		}
	}
	
	/**
	 * Called when a {@link SelectAction} is received.
	 */
	protected void handle(SelectAction action) {
		updateSelection(action);
	}
	
	/**
	 * Called when a {@link SelectAllAction} is received.
	 */
	protected void handle(SelectAllAction action) {
		updateSelection(action);
	}
	
	/**
	 * Called when a {@link CollapseExpandAction} is received.
	 */
	protected void handle(CollapseExpandAction action) {
		if (action.getCollapseIds() != null)
			expandedElements.removeAll(action.getCollapseIds());
		if (action.getExpandIds() != null)
			expandedElements.addAll(action.getExpandIds());
		
		IDiagramExpansionListener expansionListener = getExpansionListener();
		if (expansionListener != null) {
			expansionListener.expansionChanged(action, this);
		}
	}
	
	/**
	 * Called when a {@link CollapseExpandAllAction} is received.
	 */
	protected void handle(CollapseExpandAllAction action) {
		if (action.isExpand())
			new SModelIndex(getModel()).allIds().forEach(id -> expandedElements.add(id));
		else
			expandedElements.clear();
		
		IDiagramExpansionListener expansionListener = getExpansionListener();
		if (expansionListener != null) {
			expansionListener.expansionChanged(action, this);
		}
	}
	
	/**
	 * Called when a {@link OpenAction} is received.
	 */
	protected void handle(OpenAction action) {
		IDiagramOpenListener openListener = getOpenListener();
		if (openListener != null) {
			openListener.elementOpened(action, this);
		}
	}
	
	/**
	 * Called when a {@link LayoutAction} is received.
	 */
	protected void handle(LayoutAction action) {
		if (needsServerLayout(getModel(), action)) {
			// Clone the current model, as it has already been sent to the client with the old revision
			SModelCloner cloner = getSModelCloner();
			SModelRoot newRoot = cloner.clone(getModel());
			synchronized(modelLock) {
				newRoot.setRevision(++revision);
				currentRoot = newRoot;
			}
			// the actual layout is performed in doSubmitModel
			doSubmitModel(newRoot, true, action);
		}
	}
	
	public static class DefaultDiagramState implements IDiagramState {

		private DefaultDiagramServer server;

		DefaultDiagramState(DefaultDiagramServer server) {
			this.server = server;
		}
		
		@Override
		public Map<String, String> getOptions() {
			return server.options;
		}
		
		@Override
		public String getClientId() {
			return server.clientId;
		}
		
		@Override
		public SModelRoot getCurrentModel() {
			return server.currentRoot;
		}
		
		@Override
		public Set<String> getExpandedElements() {
			return server.expandedElements;
		}
		
		@Override
		public Set<String> getSelectedElements() {
			return server.selectedElements;
		}
	}
}
